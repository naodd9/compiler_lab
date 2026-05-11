/* ============================================================
 *  codegen.h  –  Level 008
 *
 *  Included by lexer.l to create ConstantInt nodes.
 * ============================================================ */
#pragma once

#include "llvm_includes.h"

extern std::unique_ptr<llvm::LLVMContext> TheContext;

inline llvm::Value* makeInt(int v) {
    return llvm::ConstantInt::get(
        *TheContext,
        llvm::APInt(32, (uint64_t)v, /*isSigned=*/true));
}