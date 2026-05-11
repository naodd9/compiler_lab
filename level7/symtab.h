/* ============================================================
 *  symtab.h  –  Level 007
 *
 *  A simple flat symbol table.
 *
 *  Each variable is stored as an alloca instruction in the
 *  entry block of @main.  We map  name -> AllocaInst*  so
 *  that every reference to a variable can emit a `load` and
 *  every assignment can emit a `store`.
 * ============================================================ */
#pragma once

#include "llvm_includes.h"
#include <map>
#include <string>

/* Forward-declared LLVM globals (defined in parser.y / main()) */
extern std::unique_ptr<llvm::LLVMContext> TheContext;
extern std::unique_ptr<llvm::Module>      TheModule;
extern std::unique_ptr<llvm::IRBuilder<>> Builder;

/* ── SymbolTable ─────────────────────────────────────────── */
class SymbolTable {
public:
    /* Declare a new variable (or return existing alloca).
     * Creates an alloca in the current function's entry block. */
    llvm::AllocaInst* declare(const std::string& name,
                               llvm::Function*    fn)
    {
        auto it = table_.find(name);
        if (it != table_.end())
            return it->second;      /* already declared – reuse */

        /* Insert alloca at the very start of the entry block so
         * that mem2reg can promote them cleanly later.          */
        llvm::IRBuilder<> entryBuilder(
            &fn->getEntryBlock(),
            fn->getEntryBlock().begin());

        llvm::AllocaInst* alloca =
            entryBuilder.CreateAlloca(
                llvm::Type::getInt32Ty(*TheContext),
                /*ArraySize=*/nullptr,
                name);

        table_[name] = alloca;
        return alloca;
    }

    /* Look up an existing variable; returns nullptr if unknown. */
    llvm::AllocaInst* lookup(const std::string& name) const {
        auto it = table_.find(name);
        return (it != table_.end()) ? it->second : nullptr;
    }

    void clear() { table_.clear(); }

private:
    std::map<std::string, llvm::AllocaInst*> table_;
};

/* Global symbol table (defined in parser.y) */
extern SymbolTable SymTab;
