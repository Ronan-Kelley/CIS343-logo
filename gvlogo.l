/*
 * group member(s):
 *      Ronan Kelley
 */
%{
#include <stdio.h>
#include <stdlib.h>
#include "gvlogo.tab.h"

extern void yyerror(const char* s);
%}

%%

\$[A-Z]                 { yytext[0] = yytext[1]; yytext[1] = '\0'; yylval.s = yytext; return VARIABLE; }
\"[^"]+\"               { yylval.s = yytext; return STRING; }
[A-Za-z]+\.[A-Za-z]+    { yylval.s = yytext; return STRING; }
-?[0-9]+(\.[0-9]+)?     { yylval.f = atof(yytext); return NUMBER; }
\+                      { return PLUS; }
-                       { return SUB; }
\*                      { return MULT; }
\/                      { return DIV; }
=                       { return EQUAL; }
penup                   { return PENUP; }
pendown                 { return PENDOWN; }
print                   { return PRINT; }
save                    { return SAVE; }
color                   { return CHANGE_COLOR; }
clear                   { return CLEAR; }
turn                    { return TURN; }
move                    { return MOVE; }
goto                    { return GOTO; }
where                   { return WHERE; }
end                     { return END; }
;                       { return SEP; }
[ \t\r\n]               { ; }
.                       { yyerror("Lexing Syntax error.\n"); }

%%
