%{
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

int yylex(void);
void yyerror(const char* s) { fprintf(stderr, "Parse error: %s\n", s); }
%}

%union {
    int ival;
    void* node;
}

%token <ival> INTEGER
%token NEWLINE

%type <ival> expr

%left '+' '-'
%left '*' '/'
%right UMINUS

%%

input
    : /* empty */
    | input line
    ;

line
    : NEWLINE
    | expr NEWLINE  {
        printf("Value: %d\n", $1);
      }
    ;

expr
    : INTEGER               { $$ = $1; }
    | expr '+' expr         { $$ = $1 + $3; }
    | expr '-' expr         { $$ = $1 - $3; }
    | expr '*' expr         { $$ = $1 * $3; }
    | expr '/' expr         { $$ = $1 / $3; }
    | '(' expr ')'          { $$ = $2; }
    | '-' expr  %prec UMINUS {
        $$ = -$2;
      }
    ;

%%

int main() {
    printf("Level 003 - Arithmetic Evaluation\n");
    printf("Enter arithmetic expressions. Press Ctrl+D to compute.\n\n");
    return yyparse();
}

int yywrap() {
    return 1;
}