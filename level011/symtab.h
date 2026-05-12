#pragma once

#include "llvm_includes.h"
#include <map>
#include <string>
#include <stack>

extern std::unique_ptr<llvm::LLVMContext> TheContext;
extern std::unique_ptr<llvm::Module>      TheModule;
extern std::unique_ptr<llvm::IRBuilder<>> Builder;

class SymbolTable {
public:
    llvm::AllocaInst* declare(const std::string& name, llvm::Function* fn) {
        std::string key = name + "@" + std::to_string((uintptr_t)fn);
        auto it = vars_.find(key);
        if (it != vars_.end()) return it->second;

        llvm::IRBuilder<> entryBuilder(&fn->getEntryBlock(), fn->getEntryBlock().begin());
        llvm::AllocaInst* alloca = entryBuilder.CreateAlloca(
            llvm::Type::getInt32Ty(*TheContext), nullptr, name);
        vars_[key] = alloca;
        return alloca;
    }

    llvm::AllocaInst* lookup(const std::string& name, llvm::Function* fn) const {
        std::string key = name + "@" + std::to_string((uintptr_t)fn);
        auto it = vars_.find(key);
        return (it != vars_.end()) ? it->second : nullptr;
    }

    void pushScope(llvm::Function* fn) {
        scopeStack_.push(fn);
    }

    void popScope() {
        vars_.clear();
        if (!scopeStack_.empty()) scopeStack_.pop();
    }

    llvm::Function* getCurrentFn() const {
        if (scopeStack_.empty()) return nullptr;
        return scopeStack_.top();
    }

    void setRetAlloca(llvm::AllocaInst* a) { retAlloca_ = a; }
    llvm::AllocaInst* getRetAlloca() const { return retAlloca_; }

    void clear() { vars_.clear(); }

private:
    std::map<std::string, llvm::AllocaInst*> vars_;
    std::stack<llvm::Function*> scopeStack_;
    llvm::AllocaInst* retAlloca_ = nullptr;
};

extern SymbolTable SymTab;