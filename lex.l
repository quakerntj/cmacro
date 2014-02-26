%{
#include <stdlib.h>
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
        yylval.buffer.lineno = yylineno; \
        yylval.buffer.token = (t); \
        yylval.buffer.data = strdup(yytext); \
    } while(0)

%}

%s PREPROCESSOR

seperatespace  ([ \t]+)

whitespace  ([ \t\n\r]+)
idenetifier [a-zA-Z_][a-zA-Z_0-9]*

%%
    /* variables */

^{whitespace}*# {
    /* preprocessor begin */
    BEGIN(PREPROCESSOR);
    gcondition = "preprocessor"; 
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

<INITIAL,PREPROCESSOR>[-+]?([0-9]\+\.|\.[0-9]+|[0-9]+\.[0-9]+) {
    gFloat = atof(yytext);
    return FLOAT;
}

<INITIAL,PREPROCESSOR>[-+]?[0-9]+ {
    gInteger = atoi(yytext);
    return INTEGER;
}

<INITIAL,PREPROCESSOR>true {
    gBool = true;
    return BOOL;
}

<INITIAL,PREPROCESSOR>false {
    gBool = false;
    return BOOL;
}

<INITIAL,PREPROCESSOR>{seperatespace} {
    if (gEnableSpace)
        return SEPERATE_SPACE;
}


<PREPROCESSOR>\n {BEGIN(INITIAL); gcondition = "initial"; return NEWLINE;}
<PREPROCESSOR>\\\\n ;  // change line

<PREPROCESSOR>{idenetifier} {return PRE_IDENTIFIER;}
<INITIAL>{idenetifier} {return IDENTIFIER;}

    /* skip whitespace */
{whitespace} ;

<INITIAL,PREPROCESSOR>; {return ';';}
<INITIAL,PREPROCESSOR>, {return ',';}
<INITIAL,PREPROCESSOR>\( {return '(';}
<INITIAL,PREPROCESSOR>\) {return ')';}
<INITIAL,PREPROCESSOR>\{ {return '{';}
<INITIAL,PREPROCESSOR>\} {return '}';}

    /* anything else is ignored */
. ;

%%

int yywrap(void) {
    return 1;
}
