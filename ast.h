#ifndef AST_H
#define AST_H

// Statement types
typedef enum {
    STMT_ASSIGN,
    STMT_PRINT,
    STMT_IF,
    STMT_WHILE,      // NEW
    STMT_FOR         // NEW
} stmt_type;

// Expression types
typedef enum {
    EXPR_CONST,
    EXPR_VAR,
    EXPR_BINOP,
    EXPR_STRING      // NEW
} expr_type;

// Operators
typedef enum {
    OP_PLUS, OP_MINUS, OP_MUL, OP_DIV,
    OP_GT, OP_LT, OP_EQ,
    OP_GE, OP_LE, OP_NE,     // NEW
    OP_AND, OP_OR            // NEW
} op_type;

// Expression structure
typedef struct expr {
    expr_type type;
    union {
        double value;       // numeric constant
        char *var_name;     // variable identifier
        char *str_value;    // NEW — string literal

        struct {
            op_type op;
            struct expr *left;
            struct expr *right;
        } binop;
    };
} expr_t;

// Forward declaration for stmt_list_t
struct stmt_list;

// Statement structure
typedef struct stmt {
    stmt_type type;

    union {

        struct {            // a = expr;
            char *var_name;
            expr_t *expr;
        } assign;

        struct {            // print expr;
            expr_t *expr;
        } print;

        struct {            // if (cond) {then} else {else}
            expr_t *cond;
            struct stmt_list *then_block;
            struct stmt_list *else_block;
        } if_stmt;

        struct {            // while (cond) {body}
            expr_t *cond;
            struct stmt_list *body;
        } while_stmt;       // NEW

        struct {            // for (init; cond; incr) {body}
            struct stmt *init;
            expr_t *cond;
            struct stmt *incr;
            struct stmt_list *body;
        } for_stmt;         // NEW
    };

    struct stmt *next;
} stmt_t;

// Statement list
typedef struct stmt_list {
    stmt_t *head;
    stmt_t *tail;
} stmt_list_t;

#endif
