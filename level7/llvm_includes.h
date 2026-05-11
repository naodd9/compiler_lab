/* ============================================================
 *  llvm_includes.h
 *
 *  Must be the FIRST include in every translation unit that
 *  uses parser.tab.h.  It ensures llvm::Value is a complete
 *  type before the %union that references it is expanded.
 * ============================================================ */
#pragma once

#include "llvm/IR/LLVMContext.h"
#include "llvm/IR/Module.h"
#include "llvm/IR/IRBuilder.h"
#include "llvm/IR/Verifier.h"
#include "llvm/IR/Constants.h"
#include "llvm/ADT/APInt.h"
#include "llvm/Support/raw_ostream.h"
#include "llvm/Support/FileSystem.h"
#include "llvm/ExecutionEngine/ExecutionEngine.h"
#include "llvm/ExecutionEngine/GenericValue.h"
#include "llvm/ExecutionEngine/SectionMemoryManager.h"
#include "llvm/Support/TargetSelect.h"

#include <memory>
#include <vector>
#include <string>
