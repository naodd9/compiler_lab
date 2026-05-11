%{
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "parser.tab.h"
%}

%option noyywrap nounput noinput

%%

[0-9]+      { yylval.ival = atoi(yytext); return INTEGER; }

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