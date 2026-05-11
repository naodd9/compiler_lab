/* ============================================================
 *  lexer.l  –  Level 012
 *
 *  Level 011 + 1-dimensional array definition and usage.
 * ============================================================ */
%{
#include "llvm_includes.h"
#include "parser.tab.h"
#include "symtab.h"
#include <stdlib.h>
#include <stdio.h>
#include <string.h>
%}

%option noyywrap nounput noinput

%%

[0-9]+                  { yylval.ival = atoi(yytext); return INTEGER; }

[a-zA-Z_][a-zA-Z0-9_]*  {
    yylval.sval = strdup(yytext);
    if (strcmp(yytext, "if") == 0) return IF;
    if (strcmp(yytext, "else") == 0) return ELSE;
    if (strcmp(yytext, "while") == 0) return WHILE;
    if (strcmp(yytext, "and") == 0) return AND;
    if (strcmp(yytext, "or") == 0) return OR;
    if (strcmp(yytext, "def") == 0) return DEF;
    if (strcmp(yytext, "int") == 0) return INT;
    return IDENT;
}

"+"                     { return '+'; }
"-"                     { return '-'; }
"*"                     { return '*'; }
"/"                     { return '/'; }
"("                     { return '('; }
")"                     { return ')'; }
"="                     { return '='; }
";"                     { return ';'; }
"{"                     { return '{'; }
"}"                     { return '}'; }
","                     { return ','; }
"["                     { return '['; }
"]"                     { return ']'; }
">"                     { return '>'; }
"<"                     { return '<'; }

">="                    { return GE; }
"<="                    { return LE; }
"=="                    { return EQ; }
"!="                    { return NE; }

[ \t\r]+                { /* skip whitespace */ }
"\n"                    { return NEWLINE; }

.                       { fprintf(stderr, "Lexer error: unknown char '%c'\n", yytext[0]); }

%%