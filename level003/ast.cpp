/* ============================================================
 *  ast.cpp  –  Level 003
 *
 *  AST node implementation.
 * ============================================================ */
#include "ast.h"
#include <stdio.h>
#include <stdlib.h>

ASTNode* makeInteger(int v) {
    ASTNode* node = new ASTNode();
    node->kind  = NK_Integer;
    node->value = v;
    node->left  = nullptr;
    node->right = nullptr;
    return node;
}

ASTNode* makeBinaryOp(NodeKind kind, ASTNode* left, ASTNode* right) {
    ASTNode* node = new ASTNode();
    node->kind  = kind;
    node->value = 0;
    node->left  = left;
    node->right = right;
    return node;
}

ASTNode* makeNegate(ASTNode* child) {
    ASTNode* node = new ASTNode();
    node->kind  = NK_Negate;
    node->value = 0;
    node->left  = child;
    node->right = nullptr;
    return node;
}

void freeAST(ASTNode* node) {
    if (!node) return;
    freeAST(node->left);
    freeAST(node->right);
    delete node;
}

void printAST(ASTNode* node, int indent) {
    if (!node) return;
    for (int i = 0; i < indent; i++) printf("  ");
    switch (node->kind) {
        case NK_Integer: printf("Integer(%d)\n", node->value); break;
        case NK_Add:     printf("Add\n"); break;
        case NK_Sub:     printf("Sub\n"); break;
        case NK_Mul:     printf("Mul\n"); break;
        case NK_Div:     printf("Div\n"); break;
        case NK_Negate:  printf("Negate\n"); break;
        case NK_Paren:   printf("Paren\n"); break;
    }
    printAST(node->left, indent + 1);
    printAST(node->right, indent + 1);
}

int evalAST(ASTNode* node) {
    if (!node) return 0;
    switch (node->kind) {
        case NK_Integer: return node->value;
        case NK_Add:     return evalAST(node->left) + evalAST(node->right);
        case NK_Sub:     return evalAST(node->left) - evalAST(node->right);
        case NK_Mul:     return evalAST(node->left) * evalAST(node->right);
        case NK_Div:     return evalAST(node->left) / evalAST(node->right);
        case NK_Negate:  return -evalAST(node->left);
        case NK_Paren:   return evalAST(node->left);
    }
    return 0;
}