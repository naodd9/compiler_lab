%{
/* ============================================================
 *  lexer.l  –  Level 007
 *
 *  New tokens vs Level 004:
 *    IDENT   – variable name  [a-zA-Z_][a-zA-Z0-9_]*
 *    '='     – assignment operator
 *    ';'     – statement terminator
 *
 *  llvm_includes.h must precede parser.tab.h so that
 *  llvm::Value is complete when the %union is parsed.
 * ============================================================ */
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

[a-zA-Z_][a-zA-Z0-9_]* {
                          /* Return a heap-allocated copy of the name.
                           * The parser action is responsible for freeing it
                           * (or it lives until program end — fine for now). */
                          yylval.sval = strdup(yytext);
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

[ \t\r]+                { /* skip whitespace */ }
"\n"                    { return NEWLINE; }

.                       { fprintf(stderr,
                            "Lexer error: unknown char '%c'\n",
                            yytext[0]); }

%%
