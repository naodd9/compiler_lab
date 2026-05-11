%{
#include "llvm_includes.h"
#include "parser.tab.h"
#include "codegen.h"
#include <stdlib.h>
#include <stdio.h>
%}

%option noyywrap nounput noinput

%%

[0-9]+      { yylval.val = makeInt(atoi(yytext)); return INTEGER; }

"+"         { return '+'; }
"-"         { return '-'; }
"*"         { return '*'; }
"/"         { return '/'; }
"("         { return '('; }
")"         { return ')'; }

[ \t\r]+    { /* skip whitespace */ }
"\n"        { return NEWLINE; }

.           { fprintf(stderr, "Lexer error: unknown char '%c'\n", yytext[0]); }

%%