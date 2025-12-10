%{
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "ast.h"

/* Variable storage */
typedef struct var {
    char *name;
    double value;
    char *str_value;   // NEW — store string variables
    struct var *next;
} var_t;

var_t *var_list = NULL;

/* Forward declarations */
int yylex(void);
void yyerror(const char *s);

void set_var(const char *name, double value);
void set_var_str(const char *name, const char *s);
double get_var(const char *name);
char *get_var_str(const char *name);

expr_t *make_const(double val);
expr_t *make_var(char *name);
expr_t *make_string(char *s);
expr_t *make_binop(op_type op, expr_t *left, expr_t *right);

stmt_t *make_assign(char *name, expr_t *expr);
stmt_t *make_print(expr_t *expr);
stmt_t *make_if(expr_t *cond, stmt_list_t *then_block, stmt_list_t *else_block);
stmt_t *make_while(expr_t *cond, stmt_list_t *body);
stmt_t *make_for(stmt_t *init, expr_t *cond, stmt_t *incr, stmt_list_t *body);

stmt_list_t *make_stmt_list(void);
void stmt_list_append(stmt_list_t *list, stmt_t *stmt);

double eval_expr(expr_t *e);
char *eval_expr_str(expr_t *e);

void execute_stmt(stmt_t *s);
void execute_stmt_list(stmt_list_t *list);

stmt_list_t *root = NULL;

/* ========================= VARIABLE SET ======================== */

void set_var(const char *name, double value) {
    var_t *v = var_list;
    while (v) {
        if (strcmp(v->name, name) == 0) {
            v->value = value;
            if (v->str_value) { free(v->str_value); v->str_value = NULL; }
            return;
        }
        v = v->next;
    }
    v = malloc(sizeof(var_t));
    v->name = strdup(name);
    v->value = value;
    v->str_value = NULL;
    v->next = var_list;
    var_list = v;
}

void set_var_str(const char *name, const char *s) {
    var_t *v = var_list;
    while (v) {
        if (strcmp(v->name, name) == 0) {
            if (v->str_value) free(v->str_value);
            v->str_value = strdup(s);
            return;
        }
        v = v->next;
    }
    v = malloc(sizeof(var_t));
    v->name = strdup(name);
    v->value = 0;
    v->str_value = strdup(s);
    v->next = var_list;
    var_list = v;
}

/* ------------------ Variable Get ------------------ */

double get_var(const char *name) {
    var_t *v = var_list;
    while (v) {
        if (strcmp(v->name, name) == 0)
            return v->value;
        v = v->next;
    }
    fprintf(stderr, "Error: variable '%s' not defined.\n", name);
    return 0.0;
}

/* FIX 1 — return NULL when variable is not a string */
char *get_var_str(const char *name) {
    var_t *v = var_list;
    while (v) {
        if (strcmp(v->name, name) == 0)
            return v->str_value;   // may be NULL
        v = v->next;
    }
    return NULL;
}

/* ========================= EXPR ======================== */

expr_t *make_const(double val) {
    expr_t *e = malloc(sizeof(expr_t));
    e->type = EXPR_CONST;
    e->value = val;
    return e;
}

expr_t *make_var(char *name) {
    expr_t *e = malloc(sizeof(expr_t));
    e->type = EXPR_VAR;
    e->var_name = name;
    return e;
}

expr_t *make_string(char *s) {
    expr_t *e = malloc(sizeof(expr_t));
    e->type = EXPR_STRING;

    s[strlen(s)-1] = '\0'; 
    e->str_value = strdup(s+1);

    return e;
}

expr_t *make_binop(op_type op, expr_t *left, expr_t *right) {
    expr_t *e = malloc(sizeof(expr_t));
    e->type = EXPR_BINOP;
    e->binop.op = op;
    e->binop.left = left;
    e->binop.right = right;
    return e;
}

/* ========================= STMT ======================== */

stmt_t *make_assign(char *name, expr_t *expr) {
    stmt_t *s = malloc(sizeof(stmt_t));
    s->type = STMT_ASSIGN;
    s->assign.var_name = name;
    s->assign.expr = expr;
    s->next = NULL;
    return s;
}

stmt_t *make_print(expr_t *expr) {
    stmt_t *s = malloc(sizeof(stmt_t));
    s->type = STMT_PRINT;
    s->print.expr = expr;
    s->next = NULL;
    return s;
}

stmt_t *make_if(expr_t *cond, stmt_list_t *then_block, stmt_list_t *else_block) {
    stmt_t *s = malloc(sizeof(stmt_t));
    s->type = STMT_IF;
    s->if_stmt.cond = cond;
    s->if_stmt.then_block = then_block;
    s->if_stmt.else_block = else_block;
    s->next = NULL;
    return s;
}

stmt_t *make_while(expr_t *cond, stmt_list_t *body) {
    stmt_t *s = malloc(sizeof(stmt_t));
    s->type = STMT_WHILE;
    s->while_stmt.cond = cond;
    s->while_stmt.body = body;
    return s;
}

stmt_t *make_for(stmt_t *init, expr_t *cond, stmt_t *incr, stmt_list_t *body) {
    stmt_t *s = malloc(sizeof(stmt_t));
    s->type = STMT_FOR;
    s->for_stmt.init = init;
    s->for_stmt.cond = cond;
    s->for_stmt.incr = incr;
    s->for_stmt.body = body;
    return s;
}

/* ========================= STMT LIST ======================== */

stmt_list_t *make_stmt_list(void) {
    stmt_list_t *list = malloc(sizeof(stmt_list_t));
    list->head = NULL;
    list->tail = NULL;
    return list;
}

void stmt_list_append(stmt_list_t *list, stmt_t *stmt) {
    if (!list->head)
        list->head = stmt;
    else
        list->tail->next = stmt;

    list->tail = stmt;
}

/* ========================= EVAL ======================== */

double eval_expr(expr_t *e) {
    if (e->type == EXPR_CONST) return e->value;
    if (e->type == EXPR_VAR) return get_var(e->var_name);
    if (e->type == EXPR_STRING) return 0;

    double l = eval_expr(e->binop.left);
    double r = eval_expr(e->binop.right);

    switch (e->binop.op) {
        case OP_PLUS: return l + r;
        case OP_MINUS: return l - r;
        case OP_MUL: return l * r;
        case OP_DIV: return l / r;
        case OP_GT: return l > r;
        case OP_LT: return l < r;
        case OP_EQ: return l == r;
        case OP_GE: return l >= r;
        case OP_LE: return l <= r;
        case OP_NE: return l != r;
        case OP_AND: return l && r;
        case OP_OR: return l || r;
    }
    return 0;
}

/* ========================= EXECUTE ======================== */

void execute_stmt(stmt_t *s) {
    switch (s->type) {

    case STMT_ASSIGN:
        if (s->assign.expr->type == EXPR_STRING)
            set_var_str(s->assign.var_name, s->assign.expr->str_value);
        else
            set_var(s->assign.var_name, eval_expr(s->assign.expr));
        break;

    /* FIX 2 — correctly print string or numeric variable */
    case STMT_PRINT:
        if (s->print.expr->type == EXPR_STRING) {
            printf("%s\n", s->print.expr->str_value);
        }
        else if (s->print.expr->type == EXPR_VAR) {
            char *sv = get_var_str(s->print.expr->var_name);
            if (sv != NULL)
                printf("%s\n", sv);
            else
                printf("%g\n", get_var(s->print.expr->var_name));
        }
        else {
            printf("%g\n", eval_expr(s->print.expr));
        }
        break;

    case STMT_IF:
        if (eval_expr(s->if_stmt.cond))
            execute_stmt_list(s->if_stmt.then_block);
        else if (s->if_stmt.else_block)
            execute_stmt_list(s->if_stmt.else_block);
        break;

    case STMT_WHILE:
        while (eval_expr(s->while_stmt.cond))
            execute_stmt_list(s->while_stmt.body);
        break;

    case STMT_FOR:
        execute_stmt(s->for_stmt.init);
        while (eval_expr(s->for_stmt.cond)) {
            execute_stmt_list(s->for_stmt.body);
            execute_stmt(s->for_stmt.incr);
        }
        break;
    }
}

void execute_stmt_list(stmt_list_t *list) {
    stmt_t *cur = list->head;
    while (cur) {
        execute_stmt(cur);
        cur = cur->next;
    }
}

/* ========================= GRAMMAR ======================== */

%}

%code requires { #include "ast.h" }

%union {
    double fval;
    char *str;
    expr_t *expr;
    stmt_t *stmt;
    stmt_list_t *stmt_list;
}

%token <fval> FLOAT
%token <str> IDENT
%token <str> STRING

%token PRINT IF ELSE WHILE FOR
%token ASSIGN PLUS MINUS MUL DIV
%token SEMI LBRACE RBRACE LPAREN RPAREN
%token GT LT EQ GE LE NE AND OR

%type <expr> expr condition
%type <stmt> statement if_statement
%type <stmt_list> program block

%left OR
%left AND
%nonassoc GT LT GE LE EQ NE
%left PLUS MINUS
%left MUL DIV

%%

program:
      /* empty */              { $$ = make_stmt_list(); root = $$; }
    | program statement        { stmt_list_append($1, $2); $$ = $1; root = $$; }
    ;

statement:
      IDENT ASSIGN expr SEMI      { $$ = make_assign($1, $3); }
    | PRINT expr SEMI             { $$ = make_print($2); }
    | if_statement                { $$ = $1; }
    | WHILE LPAREN condition RPAREN block { $$ = make_while($3, $5); }
    | FOR LPAREN IDENT ASSIGN expr SEMI condition SEMI IDENT ASSIGN expr RPAREN block
    {
        stmt_t *init = make_assign($3, $5);
        stmt_t *incr = make_assign($9, $11);
        $$ = make_for(init, $7, incr, $13);
    }
    ;

if_statement:
      IF LPAREN condition RPAREN block
          { $$ = make_if($3, $5, NULL); }
    | IF LPAREN condition RPAREN block ELSE block
          { $$ = make_if($3, $5, $7); }
    ;

block:
      LBRACE program RBRACE       { $$ = $2 ? $2 : make_stmt_list(); }
    ;

condition:
      condition AND condition     { $$ = make_binop(OP_AND, $1, $3); }
    | condition OR condition      { $$ = make_binop(OP_OR, $1, $3); }
    | expr GT expr                { $$ = make_binop(OP_GT, $1, $3); }
    | expr LT expr                { $$ = make_binop(OP_LT, $1, $3); }
    | expr GE expr                { $$ = make_binop(OP_GE, $1, $3); }
    | expr LE expr                { $$ = make_binop(OP_LE, $1, $3); }
    | expr NE expr                { $$ = make_binop(OP_NE, $1, $3); }
    | expr EQ expr                { $$ = make_binop(OP_EQ, $1, $3); }
    ;

expr:
      expr PLUS expr              { $$ = make_binop(OP_PLUS, $1, $3); }
    | expr MINUS expr             { $$ = make_binop(OP_MINUS, $1, $3); }
    | expr MUL expr               { $$ = make_binop(OP_MUL, $1, $3); }
    | expr DIV expr               { $$ = make_binop(OP_DIV, $1, $3); }
    | FLOAT                       { $$ = make_const($1); }
    | IDENT                       { $$ = make_var($1); }
    | STRING                      { $$ = make_string($1); }
    | LPAREN expr RPAREN          { $$ = $2; }
    ;

%%

void yyerror(const char *s) {
    fprintf(stderr, "Parse error: %s\n", s);
}

/* MAIN — UNCHANGED */
int main() {

    printf("=============================================================\n");
    printf("                   MINI LANGUAGE PARSER PROJECT              \n");
    printf("=============================================================\n\n");

    printf("Submitted By:\n");
    printf("-------------------------------------------------------------\n");
    printf("%-25s %-15s\n", "Name", "ID");
    printf("-------------------------------------------------------------\n");
    printf("%-25s %-15s\n", "Shouvik Dhali", "0242220005101159");
    printf("%-25s %-15s\n", "Seikh Shariar Nehal", "0242220005101260");
    printf("%-25s %-15s\n", "Akib Ahmed", "0242220005101902");

    printf("\nSection: 63_G\n");
    printf("Daffodil International University\n\n");

    printf("Submitted To:\n");
    printf("-------------------------------------------------------------\n");
    printf("Rowzatul Zannat\n");
    printf("Lecturer, Department of CSE\n");
    printf("Faculty of Science & Information Technology\n");
    printf("Daffodil International University\n");
    printf("-------------------------------------------------------------\n");

    printf("Submission Date: 11-12-2025\n");
    printf("=============================================================\n\n");

    printf("Write your code below\n");
    printf("(NOTE: End input using Ctrl+Z then press Enter)\n");
    printf("-------------------------------------------------------------\n");

    if (yyparse() == 0) {
        execute_stmt_list(root);
    }
    return 0;
}
