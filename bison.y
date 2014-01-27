%{
#include <stdio.h>
#include <vector>
#include <string.h>
#include "bison.hpp"

extern int yylex(void);
extern void yyerror(char *);

char * gText;
double gFloat;
int gInteger;
bool gBool;

%}

%union
{
    int i;
    char * s;
    char c;
}

%token PREPROCESSOR_SYMBOL PRE_IF PRE_DEFINE FLOAT INTEGER BOOL

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
    program Preprocessor
    |
    ;

Preprocessor:
    PreStatement
    ;

PreStatement:
    PRE_IF PreExpr { printf("if expr\n"); }
    ;

PreExpr:
    INTEGER {printf("I%d\n", gInteger); }
    | FLOAT {printf("F%f\n", gFloat); }
    | BOOL {printf("B%s\n", gBool ? "true" : "false"); }
    |
    ;

%%

void yyerror(char *s) {
    fprintf(stderr, "%s\n", s);
}

void usage() {
    printf(
"=================================================\n"
"Register: a-f (struct) g-l (integer)\n"
"Instruction: echo(register [,register])\n"
"Primitive Types: integer, string, struct\n"
"Comment: comment after '#'\n"
"Example:\n"
"\t#g will equal to h\n"
"\tg=0; h=1; g=h;\n"
"\t#a will be clean as null after assign to b\n"
"\ta=(1,2,\"foo\"); b=a; c=(b,g);\n"
"\techo(a,b,g,h);\n"
"=================================================\n"
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

