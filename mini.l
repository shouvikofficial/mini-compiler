%{
#include "mini.tab.h"
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
%}

digit       [0-9]
id          [a-zA-Z_][a-zA-Z0-9_]*

%%

"//".*                      { /* skip single-line comment */ }

"/*"([^*]|(\*+[^*/]))*"*/"  { /* skip multi-line comment */ }

"print"     { return PRINT; }
"if"        { return IF; }
"else"      { return ELSE; }
"while"     { return WHILE; }
"for"       { return FOR; }

"&&"        { return AND; }
"||"        { return OR; }
">="        { return GE; }
"<="        { return LE; }
"!="        { return NE; }

"="         { return ASSIGN; }
"+"         { return PLUS; }
"-"         { return MINUS; }
"*"         { return MUL; }
"/"         { return DIV; }

";"         { return SEMI; }
"{"         { return LBRACE; }
"}"         { return RBRACE; }
"("         { return LPAREN; }
")"         { return RPAREN; }

">"         { return GT; }
"<"         { return LT; }
"=="        { return EQ; }

\"([^\"\\]|\\.)*\"   {
    yylval.str = strdup(yytext);
    return STRING;
}

{digit}+(\.{digit}+)?  {
    yylval.fval = atof(yytext);
    return FLOAT;
}

{id}  {
    yylval.str = strdup(yytext);
    return IDENT;
}

[ \t\r\n]+   { /* skip whitespace */ }

.            { /* ignore unknown characters */ }

%%

int yywrap(void) { return 1; }
