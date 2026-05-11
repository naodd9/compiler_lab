/* ============================================================
 *  ast.h  –  Level 003
 *
 *  Abstract Syntax Tree node definitions.
 * ============================================================ */
#pragma once

#include <string>
#include <vector>

enum NodeKind {
    NK_Integer,
    NK_Add,
    NK_Sub,
    NK_Mul,
    NK_Div,
    NK_Negate,
    NK_Paren
};

struct ASTNode {
    NodeKind kind;
    int      value;
    ASTNode* left;
    ASTNode* right;
};

ASTNode* makeInteger(int v);
ASTNode* makeBinaryOp(NodeKind kind, ASTNode* left, ASTNode* right);
ASTNode* makeNegate(ASTNode* child);
void freeAST(ASTNode* node);
void printAST(ASTNode* node, int indent = 0);
int evalAST(ASTNode* node);