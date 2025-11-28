#ifndef AST_H
#define AST_H

typedef enum { STMT_ASSIGN, STMT_PRINT, STMT_IF } stmt_type;
typedef enum { EXPR_CONST, EXPR_VAR, EXPR_BINOP } expr_type;
typedef enum { OP_PLUS, OP_MINUS, OP_MUL, OP_DIV, OP_GT, OP_LT, OP_EQ } op_type;

typedef struct expr {
    expr_type type;
    union {
        double value;
        char *var_name;
        struct {
            op_type op;
            struct expr *left;
            struct expr *right;
        } binop;
    };
} expr_t;

typedef struct stmt {
    stmt_type type;
    union {
        struct {
            char *var_name;
            expr_t *expr;
        } assign;
        struct {
            expr_t *expr;
        } print;
        struct {
            expr_t *cond;
            struct stmt_list *then_block;
            struct stmt_list *else_block;
        } if_stmt;
    };
    struct stmt *next;
} stmt_t;

typedef struct stmt_list {
    stmt_t *head;
    stmt_t *tail;
} stmt_list_t;

#endif
