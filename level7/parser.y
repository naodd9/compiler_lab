%{
/* ============================================================
 *  parser.y  –  Level 007
 *
 *  Grammar additions vs Level 004:
 *
 *    stmt  : IDENT '=' expr ';'   -- assignment
 *          | expr ';'             -- expression-statement (print)
 *          | NEWLINE              -- blank line
 *
 *  LLVM IR strategy for variables:
 *    - Each variable lives in an alloca in @main's entry block.
 *    - Assignment  →  store i32 <value>, ptr <alloca>
 *    - Reference   →  load  i32, ptr <alloca>
 *
 *  llvm_includes.h must come first (before parser.tab.h).
 * ============================================================ */
#include "llvm_includes.h"
#include "symtab.h"
#include <cstdio>
#include <cstdlib>
#include <cstring>

/* ── LLVM global singletons ────────────────────────────────── */
std::unique_ptr<llvm::LLVMContext> TheContext;
std::unique_ptr<llvm::Module>      TheModule;
std::unique_ptr<llvm::IRBuilder<>> Builder;

/* ── Global symbol table ────────────────────────────────────  */
SymbolTable SymTab;

/* ── Pointer to @main so we can call SymTab.declare() ──────── */
static llvm::Function* MainFn = nullptr;

/* ── printf function callee (set up in main()) ─────────────── */
static llvm::Function* PrintfFn = nullptr;

int  yylex   (void);
void yyerror (const char* s) {
    fprintf(stderr, "Parser error: %s\n", s);
}

/* Helper: emit printf("%d\n", val) */
static void emitPrint(llvm::Value* val) {
    llvm::Value* fmt = Builder->CreateGlobalStringPtr("%d\n", "fmt");
    Builder->CreateCall(PrintfFn, {fmt, val});
}
%}

/* ── Value types ────────────────────────────────────────────── */
%union {
    int            ival;   /* literal integer value              */
    char*          sval;   /* heap-allocated identifier string   */
    llvm::Value*   val;    /* LLVM IR value                      */
}

/* ── Token declarations ─────────────────────────────────────── */
%token <ival>  INTEGER
%token <sval>  IDENT
%token         NEWLINE

/* ── Type declarations for non-terminals ────────────────────── */
%type  <val>   expr

/* ── Operator precedence (low → high) ───────────────────────── */
%left  '+' '-'
%left  '*' '/'
%right UMINUS

%%

/* ── Top-level: zero or more statements ─────────────────────── */
program
    : /* empty */
    | program stmt
    ;

/* ── A single statement ─────────────────────────────────────── */
stmt
    /* Assignment:  x = expr ;
     * 1. Look up (or declare) the variable → get its alloca.
     * 2. Evaluate expr → get an i32 Value*.
     * 3. Emit: store i32 <expr>, ptr <alloca>              */
    : IDENT '=' expr ';'   {
        llvm::AllocaInst* alloca = SymTab.declare($1, MainFn);
        Builder->CreateStore($3, alloca);
        free($1);   /* done with the name string */
      }

    /* Expression-statement:  expr ;
     * Evaluate and print the result.                       */
    | expr ';'             {
        emitPrint($1);
      }

    /* Blank / empty line – nothing to emit */
    | NEWLINE              { }

    /* Semicolon on its own – nothing to emit */
    | ';'                  { }
    ;

/* ── Expressions ─────────────────────────────────────────────── */
expr
    : INTEGER              {
        /* Wrap the integer literal into an LLVM i32 constant */
        $$ = llvm::ConstantInt::get(
                 *TheContext, llvm::APInt(32, $1, /*isSigned=*/true));
      }

    | IDENT                {
        /* Variable reference:
         *   1. Look up alloca in symbol table.
         *   2. Emit: load i32, ptr <alloca>                */
        llvm::AllocaInst* alloca = SymTab.lookup($1);
        if (!alloca) {
            fprintf(stderr,
                "Error: variable '%s' used before assignment.\n", $1);
            /* Emit zero so parsing can continue */
            $$ = llvm::ConstantInt::get(
                     *TheContext, llvm::APInt(32, 0, true));
        } else {
            $$ = Builder->CreateLoad(
                     llvm::Type::getInt32Ty(*TheContext), alloca, $1);
        }
        free($1);
      }

    | expr '+' expr        { $$ = Builder->CreateAdd ($1, $3, "addtmp"); }
    | expr '-' expr        { $$ = Builder->CreateSub ($1, $3, "subtmp"); }
    | expr '*' expr        { $$ = Builder->CreateMul ($1, $3, "multmp"); }
    | expr '/' expr        { $$ = Builder->CreateSDiv($1, $3, "divtmp"); }
    | '(' expr ')'         { $$ = $2; }
    | '-' expr  %prec UMINUS {
        llvm::Value* zero = llvm::ConstantInt::get(
            *TheContext, llvm::APInt(32, 0, true));
        $$ = Builder->CreateSub(zero, $2, "negtmp");
      }
    ;

%%

/* ============================================================
 *  main()
 * ============================================================ */
int main() {
    /* ── 1. Initialise LLVM ─────────────────────────────────── */
    TheContext = std::make_unique<llvm::LLVMContext>();
    TheModule  = std::make_unique<llvm::Module>("calc_module", *TheContext);
    Builder    = std::make_unique<llvm::IRBuilder<>>(*TheContext);

    /* ── 2. Create:  define i32 @main() ─────────────────────── */
    llvm::FunctionType* mainTy =
        llvm::FunctionType::get(
            llvm::Type::getInt32Ty(*TheContext), false);

    MainFn = llvm::Function::Create(
        mainTy, llvm::Function::ExternalLinkage, "main", *TheModule);

    llvm::BasicBlock* entry =
        llvm::BasicBlock::Create(*TheContext, "entry", MainFn);
    Builder->SetInsertPoint(entry);

    /* ── 3. Declare printf: i32 (ptr, ...) ─────────────────── */
    llvm::FunctionType* printfTy =
        llvm::FunctionType::get(
            llvm::Type::getInt32Ty(*TheContext),
            { llvm::PointerType::getUnqual(*TheContext) },
            /*isVarArg=*/true);

    PrintfFn = llvm::cast<llvm::Function>(
        TheModule->getOrInsertFunction("printf", printfTy).getCallee());

    /* ── 4. Parse (grammar actions emit IR) ─────────────────── */
    yyparse();

    /* ── 5. ret i32 0 ───────────────────────────────────────── */
    Builder->CreateRet(
        llvm::ConstantInt::get(*TheContext, llvm::APInt(32, 0, true)));

    /* ── 6. Verify module ───────────────────────────────────── */
    std::string errStr;
    llvm::raw_string_ostream errStream(errStr);
    if (llvm::verifyModule(*TheModule, &errStream)) {
        fprintf(stderr,
            "Module verification failed:\n%s\n", errStr.c_str());
        return 1;
    }

    /* ── 7. Write output.ll ─────────────────────────────────── */
    std::error_code EC;
    llvm::raw_fd_ostream out("output.ll", EC, llvm::sys::fs::OF_Text);
    if (EC) {
        fprintf(stderr,
            "Cannot open output.ll: %s\n", EC.message().c_str());
        return 1;
    }
    TheModule->print(out, nullptr);
    fprintf(stderr, "IR written to output.ll\n");

    std::string err;
    llvm::InitializeAllTargets();
    llvm::InitializeAllTargetMCs();
    llvm::InitializeAllAsmPrinters();
    llvm::InitializeAllAsmParsers();
    llvm::EngineBuilder builder(std::move(TheModule));
    builder.setErrorStr(&err);
    builder.setMCJITMemoryManager(std::make_unique<llvm::SectionMemoryManager>());
    llvm::ExecutionEngine* EE = builder.create();
    if (!EE) {
        fprintf(stderr, "Could not create ExecutionEngine: %s\n", err.c_str());
        return 1;
    }
    EE->finalizeObject();
    std::vector<llvm::GenericValue> args;
    EE->runFunction(MainFn, args);
    return 0;
}
