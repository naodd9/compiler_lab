%{
#include <stdio.h>
#include <stdlib.h>

int yylex(void);
void yyerror(const char* s);
%}

%token INTEGER
%token NEWLINE

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
    | expr NEWLINE  { printf("Syntax OK\n"); }
    ;

expr
    : INTEGER
    | expr '+' expr
    | expr '-' expr
    | expr '*' expr
    | expr '/' expr
    | '(' expr ')'
    | '-' expr  %prec UMINUS
    ;

%%

int main() {
    printf("Level 001 - Grammar Validation\n");
    printf("Enter arithmetic expressions. Press Ctrl+D to parse.\n\n");
    return yyparse();
}

int yywrap() {
    return 1;
}

void yyerror(const char* s) {
    fprintf(stderr, "Parse error: %s\n", s);
}