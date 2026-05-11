%{
#include "llvm_includes.h"
#include "symtab.h"
#include <cstdio>
#include <cstdlib>
#include <cstring>
#include <vector>

std::unique_ptr<llvm::LLVMContext> TheContext;
std::unique_ptr<llvm::Module>      TheModule;
std::unique_ptr<llvm::IRBuilder<>> Builder;
SymbolTable SymTab;
static llvm::Function* MainFn = nullptr;
static llvm::Function* PrintfFn = nullptr;
static llvm::Function* CurrentFn = nullptr;
static std::vector<std::string> paramNames;

int yylex(void);
void yyerror(const char* s) { fprintf(stderr, "Parser error: %s\n", s); }

static void emitPrint(llvm::Value* val) {
    llvm::Value* fmt = Builder->CreateGlobalStringPtr("%d\n", "fmt");
    Builder->CreateCall(PrintfFn, {fmt, val});
}
%}

%union {
    int            ival;
    char*          sval;
    llvm::Value*   val;
}

%token <ival>  INTEGER
%token <sval>  IDENT
%token         NEWLINE IF ELSE WHILE DEF RETURN
%token         GE LE EQ NE AND OR ','

%type  <val>   expr boolexpr

%left  OR
%left  AND
%left  GE LE EQ NE '>' '<'
%left  '+' '-'
%left  '*' '/'
%right UMINUS

%%

program
    : /* empty */
    | program stmt
    ;

stmt
    : IDENT '=' expr ';'   {
        llvm::Function* fn = CurrentFn ? CurrentFn : MainFn;
        llvm::AllocaInst* alloca = SymTab.declare($1, fn);
        Builder->CreateStore($3, alloca);
        free($1);
      }
    | DEF IDENT '(' param_list ')' '{' stmts '}' {
        llvm::FunctionType* fty = llvm::FunctionType::get(
            llvm::Type::getInt32Ty(*TheContext), false);
        llvm::Function* fn = llvm::Function::Create(fty, llvm::Function::ExternalLinkage, $2, *TheModule);
        llvm::BasicBlock* entry = llvm::BasicBlock::Create(*TheContext, "entry", fn);
        Builder->SetInsertPoint(entry);
        CurrentFn = fn;
        SymTab.pushScope(fn);
        
        int i = 0;
        for (auto& arg : fn->args()) {
            if (i < (int)paramNames.size()) {
                llvm::AllocaInst* alloca = SymTab.declare(paramNames[i], fn);
                Builder->CreateStore(&arg, alloca);
            }
            i++;
        }
        paramNames.clear();
        
        Builder->CreateRet(llvm::ConstantInt::get(*TheContext, llvm::APInt(32, 0, true)));
      }
    | IDENT '(' arg_list ')' ';' {
        llvm::Function* fn = TheModule->getFunction($1);
        if (fn) {
            Builder->CreateCall(fn, {});
        } else {
            fprintf(stderr, "Error: function '%s' not defined.\n", $1);
        }
        free($1);
      }
    | IF '(' boolexpr ')' '{' stmts '}' {
        llvm::BasicBlock* thenBB = llvm::BasicBlock::Create(*TheContext, "then", MainFn);
        llvm::BasicBlock* mergeBB = llvm::BasicBlock::Create(*TheContext, "merge", MainFn);
        llvm::Value* condVal = Builder->CreateICmpNE($3,
            llvm::ConstantInt::get(*TheContext, llvm::APInt(1, 0, false)), "boolcond");
        Builder->CreateCondBr(condVal, thenBB, mergeBB);
        Builder->SetInsertPoint(thenBB);
        Builder->CreateBr(mergeBB);
        Builder->SetInsertPoint(mergeBB);
      }
    | IF '(' boolexpr ')' '{' stmts '}' ELSE '{' stmts '}' {
        llvm::BasicBlock* thenBB = llvm::BasicBlock::Create(*TheContext, "then", MainFn);
        llvm::BasicBlock* elseBB = llvm::BasicBlock::Create(*TheContext, "else", MainFn);
        llvm::BasicBlock* mergeBB = llvm::BasicBlock::Create(*TheContext, "merge", MainFn);
        llvm::Value* condVal = Builder->CreateICmpNE($3,
            llvm::ConstantInt::get(*TheContext, llvm::APInt(1, 0, false)), "boolcond");
        Builder->CreateCondBr(condVal, thenBB, elseBB);
        Builder->SetInsertPoint(thenBB);
        Builder->CreateBr(mergeBB);
        Builder->SetInsertPoint(elseBB);
        Builder->CreateBr(mergeBB);
        Builder->SetInsertPoint(mergeBB);
      }
    | WHILE '(' boolexpr ')' '{' stmts '}' {
        llvm::BasicBlock* loopBB = llvm::BasicBlock::Create(*TheContext, "loop", MainFn);
        llvm::BasicBlock* bodyBB = llvm::BasicBlock::Create(*TheContext, "body", MainFn);
        llvm::BasicBlock* endBB = llvm::BasicBlock::Create(*TheContext, "end", MainFn);
        Builder->CreateBr(loopBB);
        Builder->SetInsertPoint(loopBB);
        llvm::Value* condVal = $3;
        llvm::Value* boolCond = Builder->CreateICmpNE(condVal,
            llvm::ConstantInt::get(*TheContext, llvm::APInt(1, 0, false)), "boolcond");
        Builder->CreateCondBr(boolCond, bodyBB, endBB);
        Builder->SetInsertPoint(bodyBB);
        Builder->CreateBr(loopBB);
        Builder->SetInsertPoint(endBB);
      }
    | expr ';'             { emitPrint($1); }
    | NEWLINE              { }
    ;

param_list
    : IDENT                 { paramNames.push_back($1); free($1); }
    | param_list ',' IDENT  { paramNames.push_back($3); free($3); }
    ;

arg_list
    : /* empty */
    | expr                  { /* ignored for now */ }
    | arg_list ',' expr     { /* ignored for now */ }
    ;

stmts
    : /* empty */
    | stmts stmt
    ;

boolexpr
    : expr '>' expr   { $$ = Builder->CreateICmpSGT($1, $3, "cmptmp"); }
    | expr '<' expr   { $$ = Builder->CreateICmpSLT($1, $3, "cmptmp"); }
    | expr GE expr    { $$ = Builder->CreateICmpSGE($1, $3, "cmptmp"); }
    | expr LE expr    { $$ = Builder->CreateICmpSLE($1, $3, "cmptmp"); }
    | expr EQ expr    { $$ = Builder->CreateICmpEQ($1, $3, "cmptmp"); }
    | expr NE expr    { $$ = Builder->CreateICmpNE($1, $3, "cmptmp"); }
    | expr            { $$ = $1; }
    ;

expr
    : INTEGER              { $$ = llvm::ConstantInt::get(*TheContext, llvm::APInt(32, $1, true)); }
    | IDENT                {
        llvm::AllocaInst* alloca = SymTab.lookup($1);
        if (!alloca) {
            fprintf(stderr, "Error: variable '%s' used before assignment.\n", $1);
            $$ = llvm::ConstantInt::get(*TheContext, llvm::APInt(32, 0, true));
        } else {
            $$ = Builder->CreateLoad(llvm::Type::getInt32Ty(*TheContext), alloca, $1);
        }
        free($1);
      }
    | expr '+' expr        { $$ = Builder->CreateAdd ($1, $3, "addtmp"); }
    | expr '-' expr        { $$ = Builder->CreateSub ($1, $3, "subtmp"); }
    | expr '*' expr        { $$ = Builder->CreateMul ($1, $3, "multmp"); }
    | expr '/' expr        { $$ = Builder->CreateSDiv($1, $3, "divtmp"); }
    | '(' expr ')'         { $$ = $2; }
    | '-' expr  %prec UMINUS {
        llvm::Value* zero = llvm::ConstantInt::get(*TheContext, llvm::APInt(32, 0, true));
        $$ = Builder->CreateSub(zero, $2, "negtmp");
      }
    ;

%%

int main() {
    TheContext = std::make_unique<llvm::LLVMContext>();
    TheModule  = std::make_unique<llvm::Module>("calc_module", *TheContext);
    Builder    = std::make_unique<llvm::IRBuilder<>>(*TheContext);

    llvm::FunctionType* mainTy =
        llvm::FunctionType::get(llvm::Type::getInt32Ty(*TheContext), false);
    MainFn = llvm::Function::Create(mainTy, llvm::Function::ExternalLinkage, "main", *TheModule);

    llvm::BasicBlock* entry = llvm::BasicBlock::Create(*TheContext, "entry", MainFn);
    Builder->SetInsertPoint(entry);

    CurrentFn = nullptr;

    llvm::FunctionType* printfTy =
        llvm::FunctionType::get(llvm::Type::getInt32Ty(*TheContext),
            { llvm::PointerType::getUnqual(*TheContext) }, true);
    PrintfFn = llvm::cast<llvm::Function>(
        TheModule->getOrInsertFunction("printf", printfTy).getCallee());

    yyparse();

    for (auto& fn : TheModule->functions()) {
        if (fn.getName() != "main" && !fn.isDeclaration()) {
            Builder->SetInsertPoint(&fn.back());
            if (!Builder->GetInsertBlock()->getTerminator()) {
                Builder->CreateRet(llvm::ConstantInt::get(*TheContext, llvm::APInt(32, 0, true)));
            }
        }
    }

    Builder->SetInsertPoint(&MainFn->back());
    Builder->CreateRet(llvm::ConstantInt::get(*TheContext, llvm::APInt(32, 0, true)));

    std::string errStr;
    llvm::raw_string_ostream errStream(errStr);
    if (llvm::verifyModule(*TheModule, &errStream)) {
        fprintf(stderr, "Module verification failed:\n%s\n", errStr.c_str());
        return 1;
    }

    std::error_code EC;
    llvm::raw_fd_ostream out("output.ll", EC, llvm::sys::fs::OF_Text);
    if (EC) { fprintf(stderr, "Cannot open output.ll: %s\n", EC.message().c_str()); return 1; }
    TheModule->print(out, nullptr);
    fprintf(stderr, "IR written to output.ll\n");

    llvm::InitializeNativeTarget();
    llvm::InitializeNativeTargetAsmPrinter();
    llvm::EngineBuilder builder(std::move(TheModule));
    std::string err;
    builder.setErrorStr(&err);
    builder.setMCJITMemoryManager(std::make_unique<llvm::SectionMemoryManager>());
    llvm::ExecutionEngine* EE = builder.create();
    if (!EE) { fprintf(stderr, "Could not create ExecutionEngine: %s\n", err.c_str()); return 1; }
    EE->finalizeObject();
    EE->runFunction(MainFn, {});
    return 0;
}