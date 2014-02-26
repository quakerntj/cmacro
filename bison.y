%{
#include <stdio.h>
#include <vector>
#include <string.h>
#include "bison.hpp"

#define DD(args...) printf(args)

extern int yylex(void);
extern void yyerror(char *);

char * gText;
double gFloat;
int gInteger;
bool gBool;
bool gEnableSpace = false;
bool gEnableNewline = false;
extern int yylineno;
extern char * yytext;
const char * gcondition;
void yyerror(const char *message)
{
  fprintf(stderr, "%d: error: '%s' at '%s' in condition %s\n", yylineno, message, yytext, gcondition);
}

typedef struct buffer_type {
    unsigned lineno;
    unsigned token;
    char *data;
} buffer_type;

%}

%union
{
    unsigned lineno;
    unsigned token;
    char *data;
}

%token PRE_IF PRE_ELSE PRE_ELIF PRE_IFDEF PRE_IFNDEF PRE_ENDIF 
%token PRE_INCLUDE PRE_PRAGMA PRE_DEFINE PRE_DEFINED PRE_IDENTIFIER IDENTIFIER
%token FLOAT INTEGER BOOL
%token NEWLINE SEPERATE_SPACE

%right "++" "--"

%left '+' '-'
%left '*' '/'
%left '<' '>' ">=" "<=" "==" "!="

%type<s> PRE_IDENTIFIER IDENTIFIER

%{
    void yyerror(char *);
    int yylex(void);
    struct FuncArg;
    struct FuncArg {
        FuncArg() : t(0), i(0), s(NULL), a(NULL) {}
        FuncArg(int _t, int _i, char * _s, std::vector<FuncArg*> * _a) : t(_t), i(_i), s(_s?strdup(_s):NULL), a(_a) {}
        ~FuncArg() { delete s; s = NULL; delete a; a = NULL; }
        FuncArg(FuncArg& o) : t(o.t), i(o.i), s(o.s), a(o.a) { o.s = NULL; o.a = NULL; }
        FuncArg& operator=(FuncArg& o) { t = o.t; i = o.i; s = o.s; a = o.a; o.s = NULL; o.a = NULL; return *this; }
        int t;
        int i;
        char * s;
        std::vector<FuncArg*> * a;
    };
    std::vector<FuncArg*> * sym['f'-'a'+1];
    void* symT['f'-'a'+1];  // Token for the pointer handle
    int symI['l'-'g'+1];
    std::vector<FuncArg*> * funcArgs;
    FuncArg * arg;
    int retI;
    std::vector<FuncArg*> * retA;
    char postIncId = 0;
    bool postInc = false;

    void setDataOf(char c, void * t) {
        symT[c] = t;
    }

    void * getDataOf(char c) {
        return symT[c];
    }

    void clearArgs(std::vector<FuncArg*> * args) {
        for (size_t i = 0; i < args->size(); i++) {
            delete (*args)[i];
            (*args)[i] = NULL;
        }
        args->clear();
    }

    void dumpArgs(std::vector<FuncArg*> * args_) {
        if (!args_) {
            printf("(NULL)");
            return;
        }
        std::vector<FuncArg*>& args = *args_;
        for (size_t i = 0; i < args.size(); i++) {
            if (i == 0)
                printf("(");
            switch (args[i]->t) {
            case 0:
                printf("%d", args[i]->i);
                break;
            case 1:
                printf("%s", args[i]->s);
                break;
            case 2:
                dumpArgs(args[i]->a);
                break;
            };
            if (i == args.size() - 1)
                printf(")");
            else
                printf(",");
        }
    }
%}

%%

program:
    program Statement
    |
    ;

Statement:
    StatementOne
    | StatementOne StatementOne
    ;

StatementOne:
    PreStatement
    | NEWLINE
    | Expr
    ;

PreStatement:
    PreIfDirective { DD("PreStatement 1\n"); }
    | PreDefineDirective { DD("PreStatement 2\n"); }
    ;

/* #if else elif endif */

PreIfDirective:
    PreIfExpendDirective PreEndifLine { DD("PreIfDirective 1\n"); }
    | PreIfExpendDirective PreElseStatement PreEndifLine { DD("PreIfDirective 2\n"); }
    ;

PreIfExpendDirective:
    PreIfElifDirective { DD("PreIfExpendDirective 1\n"); }
    | PreIfExpendDirective PreElifStatement { DD("PreIfExpendDirective 2\n"); }
    ;

PreIfElifDirective:
    PreIfStatement { DD("PreIfElifDirective\n"); }
    | PreIfStatement PreElifStatement { DD("PreIfElifDirective\n"); }
    | PreIfdefStatement { DD("PreIfElifDirective\n"); }
    | PreIfdefStatement PreElifStatement { DD("PreIfElifDirective\n"); }
    ;

PreIfStatement:
    PreIfLine { DD("PreIfStatement 1 \n"); }
    | PreIfLine Statement { DD("PreIfStatement 2\n"); }
    ;

PreIfLine:
    PreIfCheckSpace PreExpr NEWLINE { DD("PreIfLine\n");}
    ;

PreIfCheckSpace:
    PreIfStart SEPERATE_SPACE {DD("PreIfCheckSpace\n"); gEnableSpace = false;}
    ;

PreIfStart:
    PRE_IF {gEnableSpace = true;}
    ;

PreElseStatement:
    PreElseLine { DD("PreElseStatement 1 \n"); }
    | PreElseLine Statement { DD("PreElseStatement 2 \n"); }
    ;

/* #else */
PreElseLine:
    PRE_ELSE NEWLINE
    ;

/* #elif */
PreElifStatement:
    PreElifLine { DD("PreElifStatement 1 \n"); }
    | PreElifLine Statement { DD("PreElifStatement 2 \n"); }
    ;

PreElifLine:
    PreElifCheckSpace PreExpr { DD("PreElifLine\n"); }
    ;

PreElifCheckSpace:
    PreElifStart SEPERATE_SPACE {DD("PreElifCheckSpace\n"); gEnableSpace = false;}
    ;

PreElifStart:
    PRE_ELIF {gEnableSpace = true;}
    ;
    
/* #ifdef ifndef */
PreIfdefStatement:
    PreIfdefLine { DD("PreIfdefStatement 1 \n"); }
    | PreIfdefLine Statement { DD("PreIfdefStatement 2 \n"); }
    | PreIfndefLine { DD("PreIfndefStatement 1 \n"); }
    | PreIfndefLine Statement { DD("PreIfndefStatement 2 \n"); }
    ;

PreIfdefLine:
    PreIfdefCheckSpace PRE_IDENTIFIER NEWLINE { DD("PreIfdefLine\n"); }
    ;

PreIfdefCheckSpace:
    PreIfdefStart SEPERATE_SPACE {DD("PreIfdefCheckSpace\n"); gEnableSpace = false;}
    ;

PreIfdefStart:
    PRE_IFDEF {gEnableSpace = true;}
    ;
    
PreIfndefLine:
    PreIfndefCheckSpace PRE_IDENTIFIER NEWLINE { DD("PreIfndefLine\n"); }
    ;

PreIfndefCheckSpace:
    PreIfndefStart SEPERATE_SPACE {DD("PreIfndefCheckSpace\n"); gEnableSpace = false;}
    ;

PreIfndefStart:
    PRE_IFNDEF {gEnableSpace = true;}
    ;
    
/* #endif */
PreEndifLine:
    PRE_ENDIF NEWLINE
    ;

/* #define defined */
PreDefineDirective:
    PreDefineCheckIdentifier NEWLINE {DD("define 0\n");}
    | PreDefineCheckIdentifier PreInStatement NEWLINE {DD("define 1\n");}
    | PreDefineCheckIdentifier '(' PreArgumentExpr ')' PreInStatement NEWLINE {DD("define 2\n");}
    ;

PreDefineCheckIdentifier:
    PreDefineCheckSpace PRE_IDENTIFIER {}
    ;

PreDefineCheckSpace:
    PreDefineBegin SEPERATE_SPACE {gEnableSpace = false; }
    ;

PreDefineBegin:
    PRE_DEFINE {gEnableSpace = true;}
    ;

PreArgumentExpr:
    PRE_IDENTIFIER
    | PreArgumentExpr ',' PRE_IDENTIFIER
    ;

/* Macro */
PreInStatement:
    IDENTIFIER
    | PRE_IDENTIFIER
    ;

PreExpr:
    INTEGER {DD("I%d\n", gInteger); }
    | PRE_IDENTIFIER
    | FLOAT {DD("F%f\n", gFloat); /* should error */}
    | BOOL {DD("B%s\n", gBool ? "true" : "false");}
    | '(' PreExpr ')'
    | PreExpr '+' PreExpr
    | PreExpr '-' PreExpr
    | PreExpr '*' PreExpr
    | PreExpr '/' PreExpr
    ;

Expr:
    INTEGER {DD("I%d\n", gInteger); }
    | IDENTIFIER
    | FLOAT {DD("F%f\n", gFloat); /* should error */}
    | BOOL {DD("B%s\n", gBool ? "true" : "false");}
    | '(' PreExpr ')'
    | Expr '+' Expr
    | Expr '-' Expr
    | Expr '*' Expr
    | Expr '/' Expr
    ;

%%

void yyerror(char *s) {
    fprintf(stderr, "%s\n", s);
}

void usage() {
    printf(
"\n");
}

void init() {
    for (int i = 0; i < 26; i++) {
        sym[i] = NULL;
    }
}

int main(void) {
    usage();
    init();
    yyparse();
    return 0;
}

