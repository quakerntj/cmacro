%{
#include <stdlib.h>
#include "bison.hpp"
void yyerror(char *);

extern char * gText;
extern double gFloat;
extern int gInteger;
extern bool gBool;
%}

%x PREPROCESSOR

whitespace  ([ \t\n\r]+)

%%
    /* variables */

^{whitespace}*# {
    /* preprocessor begin */
    printf("<p>\n");
    BEGIN(PREPROCESSOR);
}

<PREPROCESSOR>if {
    return PRE_IF;
}

<PREPROCESSOR>[-+]?([0-9]\+\.|\.[0-9]+|[0-9]+\.[0-9]+) {
    gFloat = atof(yytext);
    return FLOAT;
}

<PREPROCESSOR>[-+]?[0-9]+ {
    gInteger = atoi(yytext);
    return INTEGER;
}

<PREPROCESSOR>true {
    gBool = true;
    return BOOL;
}

<PREPROCESSOR>false {
    gBool = false;
    return BOOL;
}

<PREPROCESSOR>define {
    return PRE_DEFINE;
}

<PREPROCESSOR>\\\n ;  // change line
<PREPROCESSOR>\n { printf("</p>\n"); BEGIN(INITIAL); }

    /* skip whitespace */
{whitespace} ;


    /* anything else is ignored */
. ;

%%

int yywrap(void) {
    return 1;
}
