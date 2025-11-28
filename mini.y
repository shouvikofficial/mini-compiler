%{
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "ast.h"

/* Variable storage */
typedef struct var {
    char *name;
    double value;
    struct var *next;
} var_t;

var_t *var_list = NULL;

/* Forward declarations */
int yylex(void);
void yyerror(const char *s);
void set_var(const char *name, double value);
double get_var(const char *name);
expr_t *make_const(double val);
expr_t *make_var(char *name);
expr_t *make_binop(op_type op, expr_t *left, expr_t *right);
stmt_t *make_assign(char *name, expr_t *expr);
stmt_t *make_print(expr_t *expr);
stmt_t *make_if(expr_t *cond, stmt_list_t *then_block, stmt_list_t *else_block);
stmt_list_t *make_stmt_list(void);
void stmt_list_append(stmt_list_t *list, stmt_t *stmt);
double eval_expr(expr_t *e);
void execute_stmt(stmt_t *s);
void execute_stmt_list(stmt_list_t *list);
void free_expr(expr_t *e);
void free_stmt(stmt_t *s);
void free_stmt_list(stmt_list_t *list);

stmt_list_t *root = NULL;

/* Implementations */

void set_var(const char *name, double value) {
    var_t *v = var_list;
    while (v) {
        if (strcmp(v->name, name) == 0) {
            v->value = value;
            return;
        }
        v = v->next;
    }
    v = malloc(sizeof(var_t));
    v->name = strdup(name);
    v->value = value;
    v->next = var_list;
    var_list = v;
}

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

expr_t *make_binop(op_type op, expr_t *left, expr_t *right) {
    expr_t *e = malloc(sizeof(expr_t));
    e->type = EXPR_BINOP;
    e->binop.op = op;
    e->binop.left = left;
    e->binop.right = right;
    return e;
}

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

stmt_list_t *make_stmt_list(void) {
    stmt_list_t *list = malloc(sizeof(stmt_list_t));
    list->head = NULL;
    list->tail = NULL;
    return list;
}

void stmt_list_append(stmt_list_t *list, stmt_t *stmt) {
    if (!list->head) {
        list->head = stmt;
        list->tail = stmt;
    } else {
        list->tail->next = stmt;
        list->tail = stmt;
    }
}

double eval_expr(expr_t *e) {
    switch (e->type) {
        case EXPR_CONST:
            return e->value;
        case EXPR_VAR:
            return get_var(e->var_name);
        case EXPR_BINOP: {
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
            }
        }
    }
    return 0.0;
}

void execute_stmt(stmt_t *s) {
    switch (s->type) {
        case STMT_ASSIGN:
            set_var(s->assign.var_name, eval_expr(s->assign.expr));
            break;
        case STMT_PRINT:
            printf("%g\n", eval_expr(s->print.expr));
            break;
        case STMT_IF: {
            double cond_val = eval_expr(s->if_stmt.cond);
            if (cond_val) {
                execute_stmt_list(s->if_stmt.then_block);
            } else if (s->if_stmt.else_block) {
                execute_stmt_list(s->if_stmt.else_block);
            }
            break;
        }
    }
}

void execute_stmt_list(stmt_list_t *list) {
    stmt_t *cur = list->head;
    while (cur) {
        execute_stmt(cur);
        cur = cur->next;
    }
}

void free_expr(expr_t *e) {
    if (!e) return;
    if (e->type == EXPR_VAR) free(e->var_name);
    else if (e->type == EXPR_BINOP) {
        free_expr(e->binop.left);
        free_expr(e->binop.right);
    }
    free(e);
}

void free_stmt(stmt_t *s) {
    if (!s) return;
    switch (s->type) {
        case STMT_ASSIGN:
            free(s->assign.var_name);
            free_expr(s->assign.expr);
            break;
        case STMT_PRINT:
            free_expr(s->print.expr);
            break;
        case STMT_IF:
            free_expr(s->if_stmt.cond);
            free_stmt_list(s->if_stmt.then_block);
            if (s->if_stmt.else_block) free_stmt_list(s->if_stmt.else_block);
            break;
    }
    free(s);
}

void free_stmt_list(stmt_list_t *list) {
    if (!list) return;
    stmt_t *cur = list->head;
    while (cur) {
        stmt_t *next = cur->next;
        free_stmt(cur);
        cur = next;
    }
    free(list);
}

%}

%code requires {
#include "ast.h"
}

%union {
    double fval;
    char *str;
    expr_t *expr;
    stmt_t *stmt;
    stmt_list_t *stmt_list;
}

%token <fval> FLOAT
%token <str> IDENT
%token PRINT IF ELSE
%token ASSIGN PLUS MINUS MUL DIV
%token SEMI LBRACE RBRACE LPAREN RPAREN
%token GT LT EQ

%type <expr> expr condition
%type <stmt> statement if_statement
%type <stmt_list> program block

%left PLUS MINUS
%left MUL DIV
%nonassoc GT LT EQ

%%

program:
      /* empty */              { $$ = make_stmt_list(); root = $$; }
    | program statement       {
        if (!$1) $$ = make_stmt_list();
        else $$ = $1;
        stmt_list_append($$, $2);
        root = $$;
    }
    ;
statement:
      IDENT ASSIGN expr SEMI  { $$ = make_assign($1, $3); }
    | PRINT expr SEMI         { $$ = make_print($2); }
    | if_statement            { $$ = $1; }
    ;

if_statement:
      IF LPAREN condition RPAREN block {
          $$ = make_if($3, $5, NULL);
      }
    | IF LPAREN condition RPAREN block ELSE block {
          $$ = make_if($3, $5, $7);
      }
    ;

block:
      LBRACE program RBRACE   {
          $$ = $2 ? $2 : make_stmt_list();
      }
    ;

condition:
      expr GT expr            { $$ = make_binop(OP_GT, $1, $3); }
    | expr LT expr            { $$ = make_binop(OP_LT, $1, $3); }
    | expr EQ expr            { $$ = make_binop(OP_EQ, $1, $3); }
    ;

expr:
      expr PLUS expr          { $$ = make_binop(OP_PLUS, $1, $3); }
    | expr MINUS expr         { $$ = make_binop(OP_MINUS, $1, $3); }
    | expr MUL expr           { $$ = make_binop(OP_MUL, $1, $3); }
    | expr DIV expr           { $$ = make_binop(OP_DIV, $1, $3); }
    | FLOAT                   { $$ = make_const($1); }
    | IDENT                   { $$ = make_var($1); }
    | LPAREN expr RPAREN      { $$ = $2; }
    ;

%%

void yyerror(const char *s) {
    fprintf(stderr, "Parse error: %s\n", s);
}

int main() {
printf("Project Name: Mini Language Parser\n\n");
printf("Submitted By: Group-3\n");
printf("Name:\t\t\tID:\n");
printf("Md Rasel Biswash\t0242310005101215\n");
printf("Md Rakib Hasan\t\t0242310005101395\n");
printf("Mst.Afiya Haque Nilasa\t0242310005101630\n");
printf("Mst.Rukaia Zahan\t0242310005101390\n");
printf("Babor Ali\t\t0242310005101954\n");
printf("\nSection: 64_M1\nDaffodil International University\n");
printf("\nSubmitted To:\nZannatul Mawa Koli\nLecturer\nDepartment of CSE\nFaculty of Science and Information Technology\nDaffodil International University\n\n");
printf("Submition Date: 14-08-2025\n\n");

printf("Write your code here(Note: To exicute ctrl+z and press enter): \n");

    if (yyparse() == 0) {
        execute_stmt_list(root);
        free_stmt_list(root);
    }
    return 0;
}
