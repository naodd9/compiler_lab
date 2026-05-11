/* ============================================================
 *  symtab.h  –  Level 009-010
 *
 *  Symbol table for variables.
 * ============================================================ */
#pragma once

#include "llvm_includes.h"
#include <map>
#include <string>

extern std::unique_ptr<llvm::LLVMContext> TheContext;
extern std::unique_ptr<llvm::Module>      TheModule;
extern std::unique_ptr<llvm::IRBuilder<>> Builder;

class SymbolTable {
public:
    llvm::AllocaInst* declare(const std::string& name, llvm::Function* fn) {
        auto it = vars_.find(name);
        if (it != vars_.end()) return it->second;

        llvm::IRBuilder<> entryBuilder(&fn->getEntryBlock(), fn->getEntryBlock().begin());
        llvm::AllocaInst* alloca = entryBuilder.CreateAlloca(
            llvm::Type::getInt32Ty(*TheContext), nullptr, name);
        vars_[name] = alloca;
        return alloca;
    }

    llvm::AllocaInst* lookup(const std::string& name) const {
        auto it = vars_.find(name);
        return (it != vars_.end()) ? it->second : nullptr;
    }

    void clear() { vars_.clear(); }

private:
    std::map<std::string, llvm::AllocaInst*> vars_;
};

extern SymbolTable SymTab;