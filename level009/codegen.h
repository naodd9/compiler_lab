/* ============================================================
 *  codegen.h  –  Level 009
 * ============================================================ */
#pragma once

#include "llvm_includes.h"

extern std::unique_ptr<llvm::LLVMContext> TheContext;

inline llvm::Value* makeInt(int v) {
    return llvm::ConstantInt::get(*TheContext, llvm::APInt(32, (uint64_t)v, true));
}