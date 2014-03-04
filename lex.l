%{
#include <stdlib.h>
#include "ATS.h"
#include "bison.hpp"
void yyerror(char *);

extern char * gText;
extern double gFloat;
extern int gInteger;
extern bool gBool;
extern bool gEnableSpace;
extern const char * gcondition;

#define SET_BUFFER(t) \
    do { \
        yylval.buffer.type = 0; \
        yylval.buffer.lineno = yylineno; \
        yylval.buffer.token = (t); \
        yylval.buffer.data = strdup(yytext); \
    } while(0)

%}

%s PREPROCESSOR

whitespace  ([ \t\n\r]+)
idenetifier [a-zA-Z_][a-zA-Z_0-9]*

%%
    /* variables */

^{whitespace}*# {
    /* preprocessor begin */
    BEGIN(PREPROCESSOR);
    gcondition = "preprocessor";
    printf("\npreprocessor+\n");
}

<PREPROCESSOR>if {
    return PRE_IF;
}

<PREPROCESSOR>else {
    return PRE_ELSE;
}

<PREPROCESSOR>elif {
    return PRE_ELIF;
}

<PREPROCESSOR>endif {
    return PRE_ENDIF;
}

<PREPROCESSOR>ifdef {
    return PRE_IFDEF;
}

<PREPROCESSOR>ifndef {
    return PRE_IFNDEF;
}

<PREPROCESSOR>define {
    return PRE_DEFINE;
}

<PREPROCESSOR>defined {
    return PRE_DEFINED;
}

<PREPROCESSOR>include {
    return PRE_INCLUDE;
}

<PREPROCESSOR>pragma {
    return PRE_PRAGMA;
}

<INITIAL,PREPROCESSOR>([0-9]\+\.|\.[0-9]+|[0-9]+\.[0-9]+) {
    gFloat = atof(yytext);
    return FLOAT;
}

<INITIAL,PREPROCESSOR>[0-9]+ {
    SET_BUFFER(INTEGER);
    return INTEGER;
}

<INITIAL,PREPROCESSOR>true {
    SET_BUFFER(INTEGER);
    return BOOL;
}

<INITIAL,PREPROCESSOR>false {
    SET_BUFFER(INTEGER);
    return BOOL;
}

<PREPROCESSOR>\n {BEGIN(INITIAL); gcondition = "initial"; return NEWLINE;}
<PREPROCESSOR>\\\\n ;  // change line

<PREPROCESSOR>{idenetifier} {SET_BUFFER(PRE_IDENTIFIER); return PRE_IDENTIFIER;}
<INITIAL>{idenetifier} {return IDENTIFIER;}

    /* skip whitespace */
{whitespace} ;

<INITIAL,PREPROCESSOR>; {return ';';}
<INITIAL,PREPROCESSOR>, {return ',';}
<INITIAL,PREPROCESSOR>\( {return '(';}
<INITIAL,PREPROCESSOR>\) {return ')';}
<INITIAL,PREPROCESSOR>\{ {return '{';}
<INITIAL,PREPROCESSOR>\} {return '}';}

<INITIAL,PREPROCESSOR>\+ {return '+';}
<INITIAL,PREPROCESSOR>\- {return '-';}
<INITIAL,PREPROCESSOR>\* {return '*';}
<INITIAL,PREPROCESSOR>\/ {return '/';}

<INITIAL,PREPROCESSOR>== {
    SET_BUFFER(EQUAL);
    return EQUAL;
}

<INITIAL,PREPROCESSOR>\!= {
    SET_BUFFER(NOTEQUAL);
    return NOTEQUAL;
}

<INITIAL,PREPROCESSOR>\>= {
    SET_BUFFER(GREATEREQUAL);
    return GREATEREQUAL;
}

<INITIAL,PREPROCESSOR>\<= {
    SET_BUFFER(LESSEQUAL);
    return LESSEQUAL;
}

<INITIAL,PREPROCESSOR>\> {
    SET_BUFFER(GREATER);
    return GREATER;
}

<INITIAL,PREPROCESSOR>\< {
    SET_BUFFER(LESS);
    return LESS;
}

    /* anything else is ignored */
. ;

%%

int yywrap(void) {
    return 1;
}
