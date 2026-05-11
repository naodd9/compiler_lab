/* ============================================================
 *  codegen.h  –  Level 006
 *
 *  Included by lexer.l to create ConstantInt nodes.
 *  llvm_includes.h must already be included before this.
 * ============================================================ */
#pragma once

#include "llvm_includes.h"

extern std::unique_ptr<llvm::LLVMContext> TheContext;

inline llvm::Value* makeInt(int v) {
    return llvm::ConstantInt::get(
        *TheContext,
        llvm::APInt(32, (uint64_t)v, /*isSigned=*/true));
}