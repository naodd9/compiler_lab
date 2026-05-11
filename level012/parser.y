%{
#include "llvm_includes.h"
#include "symtab.h"
#include <cstdio>
#include <cstdlib>
#include <cstring>

std::unique_ptr<llvm::LLVMContext> TheContext;
std::unique_ptr<llvm::Module>      TheModule;
std::unique_ptr<llvm::IRBuilder<>> Builder;
SymbolTable SymTab;
static llvm::Function* MainFn = nullptr;
static llvm::Function* PrintfFn = nullptr;

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
%token         GE LE EQ NE AND OR ',' INT

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
        llvm::AllocaInst* alloca = SymTab.declareVar($1, MainFn);
        Builder->CreateStore($3, alloca);
        free($1);
      }
    | INT IDENT '[' INTEGER ']' ';' {
        SymTab.declareArray($2, $4, MainFn);
        free($2);
      }
    | IDENT '[' expr ']' '=' expr ';' {
        ArrayInfo* info = SymTab.lookupArray($1);
        if (info) {
            llvm::Value* idx[2] = {
                llvm::ConstantInt::get(*TheContext, llvm::APInt(32, 0, false)),
                $3
            };
            llvm::Value* gep = Builder->CreateGEP(
                llvm::Type::getInt32Ty(*TheContext), info->base, idx, "arrayidx");
            Builder->CreateStore($6, gep);
        } else {
            fprintf(stderr, "Error: array '%s' not declared.\n", $1);
        }
        free($1);
      }
    | expr ';'             { emitPrint($1); }
    | NEWLINE              { }
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
    | IDENT '[' expr ']'   {
        ArrayInfo* info = SymTab.lookupArray($1);
        if (info) {
            llvm::Value* idx[2] = {
                llvm::ConstantInt::get(*TheContext, llvm::APInt(32, 0, false)),
                $3
            };
            llvm::Value* gep = Builder->CreateGEP(
                llvm::Type::getInt32Ty(*TheContext), info->base, idx, "arrayidx");
            $$ = Builder->CreateLoad(llvm::Type::getInt32Ty(*TheContext), gep, "arrayval");
        } else {
            fprintf(stderr, "Error: array '%s' not declared.\n", $1);
            $$ = llvm::ConstantInt::get(*TheContext, llvm::APInt(32, 0, true));
        }
        free($1);
      }
    | IDENT                {
        llvm::AllocaInst* alloca = SymTab.lookupVar($1);
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

    llvm::FunctionType* printfTy =
        llvm::FunctionType::get(llvm::Type::getInt32Ty(*TheContext),
            { llvm::PointerType::getUnqual(*TheContext) }, true);
    PrintfFn = llvm::cast<llvm::Function>(
        TheModule->getOrInsertFunction("printf", printfTy).getCallee());

    yyparse();

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