%{
#include "llvm_includes.h"
#include <cstdio>
#include <cstdlib>

std::unique_ptr<llvm::LLVMContext> TheContext;
std::unique_ptr<llvm::Module>      TheModule;
std::unique_ptr<llvm::IRBuilder<>> Builder;

int  yylex   (void);
void yyerror (const char* s) { fprintf(stderr, "Parser error: %s\n", s); }
%}

%union {
    llvm::Value* val;
}

%token <val> INTEGER
%token NEWLINE
%type  <val> expr

%left  '+' '-'
%left  '*' '/'
%right UMINUS

%%

input
    : /* empty */
    | input line
    ;

line
    : NEWLINE
    | expr NEWLINE  {
        llvm::Function*    printfFn = TheModule->getFunction("printf");
        llvm::FunctionCallee printfCallee(printfFn->getFunctionType(), printfFn);
        llvm::Value*       fmt = Builder->CreateGlobalStringPtr("%d\n", "fmt");
        std::vector<llvm::Value*> args = { fmt, $1 };
        Builder->CreateCall(printfCallee, args);
      }
    ;

expr
    : INTEGER               { $$ = $1; }
    | expr '+' expr         { $$ = Builder->CreateAdd ($1, $3, "addtmp"); }
    | expr '-' expr         { $$ = Builder->CreateSub ($1, $3, "subtmp"); }
    | expr '*' expr         { $$ = Builder->CreateMul ($1, $3, "multmp"); }
    | expr '/' expr         { $$ = Builder->CreateSDiv($1, $3, "divtmp"); }
    | '(' expr ')'          { $$ = $2; }
    | '-' expr  %prec UMINUS {
        llvm::Value* zero = llvm::ConstantInt::get(
            *TheContext, llvm::APInt(32, 0, true));
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
    llvm::Function* mainFn =
        llvm::Function::Create(mainTy, llvm::Function::ExternalLinkage,
                               "main", *TheModule);
    llvm::BasicBlock* entry =
        llvm::BasicBlock::Create(*TheContext, "entry", mainFn);
    Builder->SetInsertPoint(entry);

    llvm::FunctionType* printfTy =
        llvm::FunctionType::get(
            llvm::Type::getInt32Ty(*TheContext),
            { llvm::PointerType::getUnqual(*TheContext) },
            true);
    TheModule->getOrInsertFunction("printf", printfTy);

    yyparse();

    Builder->CreateRet(
        llvm::ConstantInt::get(*TheContext, llvm::APInt(32, 0, true)));

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
    fprintf(stderr, "To generate assembly: llc-17 output.ll -o output.s\n");
    fprintf(stderr, "Then link: gcc -no-pie output.s -o calc\n");

    return 0;
}