/* ============================================================
 *  symtab.h  –  Level 012
 *
 *  Supports variables, arrays, and functions with arguments.
 * ============================================================ */
#pragma once

#include "llvm_includes.h"
#include <map>
#include <string>
#include <vector>

extern std::unique_ptr<llvm::LLVMContext> TheContext;
extern std::unique_ptr<llvm::Module>      TheModule;
extern std::unique_ptr<llvm::IRBuilder<>> Builder;

struct ArrayInfo {
    llvm::AllocaInst* base;
    int size;
};

struct FunctionInfo {
    llvm::Function* fn;
    std::vector<llvm::AllocaInst*> params;
};

class SymbolTable {
public:
    llvm::AllocaInst* declareVar(const std::string& name, llvm::Function* fn) {
        auto it = vars_.find(name);
        if (it != vars_.end()) return it->second;

        llvm::IRBuilder<> entryBuilder(&fn->getEntryBlock(), fn->getEntryBlock().begin());
        llvm::AllocaInst* alloca = entryBuilder.CreateAlloca(
            llvm::Type::getInt32Ty(*TheContext), nullptr, name);
        vars_[name] = alloca;
        return alloca;
    }

    llvm::AllocaInst* lookupVar(const std::string& name) const {
        auto it = vars_.find(name);
        return (it != vars_.end()) ? it->second : nullptr;
    }

    llvm::AllocaInst* declareArray(const std::string& name, int size, llvm::Function* fn) {
        llvm::IRBuilder<> entryBuilder(&fn->getEntryBlock(), fn->getEntryBlock().begin());
        llvm::ArrayType* arrTy = llvm::ArrayType::get(
            llvm::Type::getInt32Ty(*TheContext), size);
        llvm::AllocaInst* alloca = entryBuilder.CreateAlloca(arrTy, nullptr, name);
        arrays_[name] = {alloca, size};
        return alloca;
    }

    ArrayInfo* lookupArray(const std::string& name) {
        auto it = arrays_.find(name);
        return (it != arrays_.end()) ? &it->second : nullptr;
    }

    void declareFn(const std::string& name, const FunctionInfo& info) {
        funcs_[name] = info;
    }

    FunctionInfo* lookupFn(const std::string& name) {
        auto it = funcs_.find(name);
        return (it != funcs_.end()) ? &it->second : nullptr;
    }

    void clearVars() { vars_.clear(); }

private:
    std::map<std::string, llvm::AllocaInst*> vars_;
    std::map<std::string, ArrayInfo> arrays_;
    std::map<std::string, FunctionInfo> funcs_;
};

extern SymbolTable SymTab;