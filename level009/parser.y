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

struct LoopBlocks { llvm::BasicBlock *loop, *body, *end; };
struct IfBlocks   { llvm::BasicBlock *thenB, *elseB, *merge; };
static std::vector<LoopBlocks> loopStack;
static std::vector<IfBlocks>   ifStack;

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
%token         NEWLINE IF ELSE WHILE
%token         GE LE EQ NE AND OR

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
        llvm::AllocaInst* alloca = SymTab.declare($1, MainFn);
        Builder->CreateStore($3, alloca);
        free($1);
      }
    | IF '(' boolexpr ')' '{' {
        IfBlocks ctx;
        ctx.thenB = llvm::BasicBlock::Create(*TheContext, "then", MainFn);
        ctx.elseB = llvm::BasicBlock::Create(*TheContext, "else", MainFn);
        ctx.merge = llvm::BasicBlock::Create(*TheContext, "merge", MainFn);
        llvm::Value* condVal = Builder->CreateICmpNE($3,
            llvm::ConstantInt::get(*TheContext, llvm::APInt(32, 0, true)), "boolcond");
        Builder->CreateCondBr(condVal, ctx.thenB, ctx.elseB);
        Builder->SetInsertPoint(ctx.thenB);
        ifStack.push_back(ctx);
      } stmts '}' else_suffix
    | WHILE '(' {
        LoopBlocks ctx;
        ctx.loop = llvm::BasicBlock::Create(*TheContext, "loop", MainFn);
        ctx.body = llvm::BasicBlock::Create(*TheContext, "body", MainFn);
        ctx.end  = llvm::BasicBlock::Create(*TheContext, "end", MainFn);
        Builder->CreateBr(ctx.loop);
        Builder->SetInsertPoint(ctx.loop);
        loopStack.push_back(ctx);
      } boolexpr ')' '{' {
        LoopBlocks& ctx = loopStack.back();
        llvm::Value* boolCond = Builder->CreateICmpNE($4,
            llvm::ConstantInt::get(*TheContext, llvm::APInt(32, 0, true)), "boolcond");
        Builder->CreateCondBr(boolCond, ctx.body, ctx.end);
        Builder->SetInsertPoint(ctx.body);
      } stmts '}' {
        LoopBlocks& ctx = loopStack.back();
        Builder->CreateBr(ctx.loop);
        Builder->SetInsertPoint(ctx.end);
        loopStack.pop_back();
      }
    | expr ';'             { emitPrint($1); }
    | NEWLINE              { }
    ;

else_suffix
    : /* empty */ {
        IfBlocks& ctx = ifStack.back();
        Builder->CreateBr(ctx.merge);
        Builder->SetInsertPoint(ctx.elseB);
        Builder->CreateBr(ctx.merge);
        Builder->SetInsertPoint(ctx.merge);
        ifStack.pop_back();
      }
    | ELSE '{' {
        IfBlocks& ctx = ifStack.back();
        Builder->CreateBr(ctx.merge);
        Builder->SetInsertPoint(ctx.elseB);
      } stmts '}' {
        IfBlocks& ctx = ifStack.back();
        Builder->CreateBr(ctx.merge);
        Builder->SetInsertPoint(ctx.merge);
        ifStack.pop_back();
      }
    ;

stmts
    : /* empty */
    | stmts stmt
    ;

boolexpr
    : boolexpr AND boolexpr {
        llvm::BasicBlock* curBB = Builder->GetInsertBlock();
        llvm::BasicBlock* endBB = llvm::BasicBlock::Create(*TheContext, "and.end", MainFn);
        llvm::Value* leftBool = Builder->CreateICmpNE($1,
            llvm::ConstantInt::get(*TheContext, llvm::APInt(32, 0, true)), "and.leftbool");
        llvm::BasicBlock* rightBB = llvm::BasicBlock::Create(*TheContext, "and.right", MainFn);
        Builder->CreateCondBr(leftBool, rightBB, endBB);
        Builder->SetInsertPoint(rightBB);
        llvm::Value* rightBool = Builder->CreateICmpNE($3,
            llvm::ConstantInt::get(*TheContext, llvm::APInt(32, 0, true)), "and.rightbool");
        Builder->CreateBr(endBB);
        Builder->SetInsertPoint(endBB);
        llvm::PHINode* phi = Builder->CreatePHI(
            llvm::Type::getInt1Ty(*TheContext), 2, "and.result");
        phi->addIncoming(llvm::ConstantInt::get(*TheContext, llvm::APInt(1, 0, false)), curBB);
        phi->addIncoming(rightBool, rightBB);
        $$ = Builder->CreateZExt(phi, llvm::Type::getInt32Ty(*TheContext), "and.ext");
      }
    | boolexpr OR boolexpr {
        llvm::BasicBlock* curBB = Builder->GetInsertBlock();
        llvm::BasicBlock* endBB = llvm::BasicBlock::Create(*TheContext, "or.end", MainFn);
        llvm::Value* leftBool = Builder->CreateICmpNE($1,
            llvm::ConstantInt::get(*TheContext, llvm::APInt(32, 0, true)), "or.leftbool");
        llvm::BasicBlock* rightBB = llvm::BasicBlock::Create(*TheContext, "or.right", MainFn);
        Builder->CreateCondBr(leftBool, endBB, rightBB);
        Builder->SetInsertPoint(rightBB);
        llvm::Value* rightBool = Builder->CreateICmpNE($3,
            llvm::ConstantInt::get(*TheContext, llvm::APInt(32, 0, true)), "or.rightbool");
        Builder->CreateBr(endBB);
        Builder->SetInsertPoint(endBB);
        llvm::PHINode* phi = Builder->CreatePHI(
            llvm::Type::getInt1Ty(*TheContext), 2, "or.result");
        phi->addIncoming(llvm::ConstantInt::get(*TheContext, llvm::APInt(1, 1, false)), curBB);
        phi->addIncoming(rightBool, rightBB);
        $$ = Builder->CreateZExt(phi, llvm::Type::getInt32Ty(*TheContext), "or.ext");
      }
    | expr '>' expr   { $$ = Builder->CreateZExt(
        Builder->CreateICmpSGT($1, $3, "cmptmp"), llvm::Type::getInt32Ty(*TheContext), "cmpi32"); }
    | expr '<' expr   { $$ = Builder->CreateZExt(
        Builder->CreateICmpSLT($1, $3, "cmptmp"), llvm::Type::getInt32Ty(*TheContext), "cmpi32"); }
    | expr GE expr    { $$ = Builder->CreateZExt(
        Builder->CreateICmpSGE($1, $3, "cmptmp"), llvm::Type::getInt32Ty(*TheContext), "cmpi32"); }
    | expr LE expr    { $$ = Builder->CreateZExt(
        Builder->CreateICmpSLE($1, $3, "cmptmp"), llvm::Type::getInt32Ty(*TheContext), "cmpi32"); }
    | expr EQ expr    { $$ = Builder->CreateZExt(
        Builder->CreateICmpEQ($1, $3, "cmptmp"), llvm::Type::getInt32Ty(*TheContext), "cmpi32"); }
    | expr NE expr    { $$ = Builder->CreateZExt(
        Builder->CreateICmpNE($1, $3, "cmptmp"), llvm::Type::getInt32Ty(*TheContext), "cmpi32"); }
    | expr            { $$ = Builder->CreateZExt(
        Builder->CreateICmpNE($1,
            llvm::ConstantInt::get(*TheContext, llvm::APInt(32, 0, true)), "tobool"),
        llvm::Type::getInt32Ty(*TheContext), "tobooli32"); }
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