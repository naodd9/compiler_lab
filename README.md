# 🔧 Compiler Lab

A step-by-step compiler construction project built with **Flex**, **Bison**, and **LLVM 17**. Starting from a simple grammar validator and advancing through LLVM IR generation, control flow, functions, and multi-dimensional arrays — each level builds directly on the last.

> **Active development focus:** Levels 010 – 013

---

## 📋 Table of Contents

- [Overview](#overview)
- [Prerequisites](#prerequisites)
- [Installation](#installation)
- [Project Structure](#project-structure)
- [Level Reference](#level-reference)
- [How It Works](#how-it-works)
- [Usage](#usage)
- [Language Features by Level](#language-features-by-level)
- [Keyboard Shortcuts](#keyboard-shortcuts)
- [Troubleshooting](#troubleshooting)

---

## Overview

This project walks through building a real compiler from scratch. Each level introduces a new concept:

| Phase | Levels | What You Learn |
|-------|--------|----------------|
| **Parsing** | 001 – 003 | Lexing, grammar rules, AST construction |
| **Code Generation** | 004 – 007 | LLVM IR, x86-64 assembly, JIT execution |
| **Language Features** | 008 – 013 | Variables, control flow, functions, arrays |

The compiler targets a simple C-like language and uses LLVM as its backend for JIT execution and native code generation.

---

## Prerequisites

| Tool | Minimum Version | Purpose |
|------|----------------|---------|
| `flex` | 2.6+ | Lexical analysis (tokenizer) |
| `bison` | 3.7+ | Parser generator (grammar rules) |
| `g++` | C++17 support | Compiles the generated C++ |
| `llvm` | **17** | IR generation, JIT, assembly backend |
| `clang` | 17 | Optional: alternative linker/assembler |

> ⚠️ **LLVM version matters.** The Makefiles reference `llvm-config-17`. If you have a different version, update the `LLVM_CFG` variable in each level's `Makefile` (e.g. `llvm-config-15`).

---

## Installation

### Ubuntu / Debian

```bash
sudo apt update
sudo apt install flex bison g++ llvm-17 llvm-17-dev clang-17
```

### Verify your setup

```bash
flex --version          # e.g. 2.6.4
bison --version         # e.g. 3.8.2
llvm-config-17 --version  # e.g. 17.0.6
g++ --version           # e.g. 11.x or 13.x
```

---

## Project Structure

```
compiler_lab/
├── level001/           # Grammar validation (Flex + Bison only)
│   ├── lexer.l         # Token definitions
│   ├── parser.y        # Grammar rules
│   └── Makefile
├── level002/           # Direct computation during parsing
├── level003/           # AST construction and evaluation
│   ├── ast.h / ast.cpp # Abstract Syntax Tree node types
│   ├── lexer.l
│   └── parser.y
├── level004/           # LLVM IR generation + JIT execution
│   ├── codegen.h       # LLVM codegen helpers
│   ├── llvm_includes.h # Consolidated LLVM headers
│   ├── lexer.l
│   └── parser.y
├── level006/           # x86-64 assembly output via llc-17
├── level7/             # Variable assignment + JIT (named level7)
├── level008/           # if/else and while control flow
│   ├── symtab.h        # Symbol table for variables
│   ├── lexer.l
│   └── parser.y
├── level009/           # Short-circuit and / or operators
├── level010/           # Functions without arguments
├── level011/           # Functions with arguments
├── level012/           # 1D arrays
└── level013/           # 2D arrays (most complete level)
    ├── symtab.h        # Supports vars, arrays, and functions
    ├── lexer.l
    └── parser.y
```

### Key file roles

| File | Role |
|------|------|
| `lexer.l` | Flex rules that scan raw text into tokens (integers, identifiers, operators, keywords) |
| `parser.y` | Bison grammar that defines how tokens combine into valid programs; contains inline LLVM IR codegen actions |
| `symtab.h` | Symbol table tracking variables, arrays, and functions as LLVM `AllocaInst*` pointers |
| `codegen.h` | Helper wrappers around LLVM context, module, and IR builder globals |
| `llvm_includes.h` | Single header that pulls in all required LLVM headers |
| `Makefile` | Drives `flex → bison → g++ → ./calc` build pipeline |

---

## Level Reference

### Level 001 — Grammar Validation
Validates arithmetic expression syntax using Flex and Bison. No computation. Confirms the parser can recognize valid inputs.

```
2 + 3       → Syntax OK
5 * (2 - 1) → Syntax OK
2 ++ 3      → Parse error
```

---

### Level 002 — Direct Computation
Evaluates arithmetic expressions inline during parsing. No AST — results fall directly out of Bison's `$$` semantic values.

```
2 + 3        → 5
(2 + 3) * 4  → 20
10 / 3       → 3   (integer division)
```

---

### Level 003 — AST Generation
Builds an explicit Abstract Syntax Tree and then evaluates it. Prints the tree structure alongside the result.

```
Input: 2 + 3
AST:
  Add
    Integer(2)
    Integer(3)
Value: 5
```

This separation between *parsing* and *evaluation* is the foundation for all later LLVM codegen.

---

### Level 004 — LLVM IR Generation
Generates LLVM Intermediate Representation (IR) and runs it via LLVM's JIT compiler. The IR is also saved to `output.ll` for inspection.

```llvm
define i32 @main() {
entry:
  %addtmp = add i32 2, 3
  call i32 (ptr, ...) @printf(ptr @"%d\n", i32 %addtmp)
  ret i32 0
}
```

To inspect or run the IR manually:
```bash
lli-17 output.ll
```

---

### Level 006 — Assembly Code Generation
Lowers LLVM IR to native x86-64 assembly via `llc-17`. The resulting `.s` file can be assembled and linked with GCC.

```bash
make execute
# or manually:
llc-17 output.ll -o output.s
gcc -no-pie output.s -o program
./program
```

---

### Level 007 — Variables + JIT
Adds variable assignment (`x = 5;`) to the calculator and runs the whole program through LLVM's JIT engine in one shot.

---

### Level 008 — Control Flow (`if` / `while`)
Introduces `if-then-else` and `while` loops. Conditions use comparison operators. LLVM basic blocks are created explicitly for branches and loop headers.

```c
x = 10;
while (x > 0) {
    x = x - 1;
}

if (x == 0) {
    x + 1;
} else {
    x - 1;
}
```

Supported comparisons: `>`, `<`, `>=`, `<=`, `==`, `!=`

---

### Level 009 — Short-Circuit Boolean Evaluation
Adds `and` / `or` operators with proper short-circuit semantics using LLVM conditional branches — the second operand is not evaluated if the first determines the result.

```c
if (x > 3 and y < 5) {
    x + y;
}

while (i > 0 and i != 5) {
    i = i - 1;
}
```

---

### Level 010 — Functions (No Arguments)
Function definitions and calls. Functions contain their own statement blocks and return a value.

```c
def greet() {
    x = 10;
    x;
}

greet();
```

---

### Level 011 — Functions with Arguments
Extends functions to accept parameters. Each parameter is an `AllocaInst` in LLVM's entry block, scoped to the function.

```c
def add(a, b) {
    a + b;
}

def max(a, b) {
    if (a > b) {
        a;
    } else {
        b;
    }
}

add(3, 5);     // → 8
max(10, 20);   // → 20
```

---

### Level 012 — 1D Arrays
Declares and uses fixed-size integer arrays backed by LLVM `ArrayType` allocations. Index expressions are arbitrary `expr` nodes.

```c
int nums[5];
nums[0] = 10;
nums[1] = 20;
nums[0] + nums[1];   // → 30
```

---

### Level 013 — 2D Arrays *(most complete level)*
Extends arrays to two dimensions. The symbol table tracks `rows × cols` layout and computes GEP (GetElementPointer) indices with row-major ordering.

```c
int matrix[2][3];
matrix[0][0] = 1;
matrix[0][1] = 2;
matrix[1][2] = 6;

matrix[0][1];   // → 2
matrix[1][2];   // → 6
```

The `symtab.h` at this level is the most complete version, supporting scalar variables, 1D arrays, 2D arrays, and named functions all in one class.

---

## How It Works

The compilation pipeline in each level follows the same pattern:

```
Source text
    │
    ▼
┌─────────┐
│  Flex   │  lexer.l  →  tokenizes input into INTEGER, IDENT, keyword tokens
└────┬────┘
     │ token stream
     ▼
┌─────────┐
│  Bison  │  parser.y →  matches grammar rules, fires semantic actions
└────┬────┘
     │ in-action LLVM API calls
     ▼
┌──────────────┐
│  LLVM IR     │  TheModule / IRBuilder<> construct SSA form IR
└────┬─────────┘
     │
     ├──▶  JIT (lli / ExecutionEngine)  →  run immediately
     └──▶  llc-17  →  output.s  →  gcc  →  native binary
```

### LLVM globals used across all levels

```cpp
std::unique_ptr<llvm::LLVMContext> TheContext;  // owns all LLVM types/values
std::unique_ptr<llvm::Module>      TheModule;   // the compilation unit
std::unique_ptr<llvm::IRBuilder<>> Builder;     // emits IR instructions
SymbolTable                        SymTab;      // maps names → AllocaInst*
```

---

## Usage

### Build a level

```bash
cd level013
make
```

### Run the compiler

```bash
./calc
```

Type your program, then press **Ctrl+D** (Linux/Mac) or **Ctrl+Z + Enter** (Windows) to signal end of input and trigger JIT execution.

### Clean build artifacts

```bash
make clean
```

### Inspect the generated IR

After running `./calc`, the IR is written to `output.ll`:

```bash
cat output.ll
lli-17 output.ll   # run via interpreter
```

---

## Language Features by Level

| Feature | First Available |
|---------|----------------|
| Integer literals | Level 001 |
| `+`, `-`, `*`, `/` | Level 001 |
| Unary minus | Level 001 |
| Parentheses | Level 001 |
| Expression evaluation | Level 002 |
| AST visualization | Level 003 |
| LLVM IR output | Level 004 |
| x86-64 assembly output | Level 006 |
| Variable assignment (`x = 5;`) | Level 007 |
| `if` / `else` | Level 008 |
| `while` | Level 008 |
| Comparison operators (`>`, `<`, `==`, …) | Level 008 |
| `and`, `or` (short-circuit) | Level 009 |
| Function definition (no args) | Level 010 |
| Function definition (with args) | Level 011 |
| 1D arrays (`int arr[n]`) | Level 012 |
| 2D arrays (`int arr[r][c]`) | Level 013 |

---

## Keyboard Shortcuts

| Action | Linux / Mac | Windows |
|--------|-------------|---------|
| End input / execute | `Ctrl+D` | `Ctrl+Z` then `Enter` |
| Cancel / abort | `Ctrl+C` | `Ctrl+C` |

---

## Troubleshooting

**Wrong LLVM version error**
```
llvm-config-17: command not found
```
Edit the `Makefile` in the level you're building:
```makefile
LLVM_CFG = llvm-config-17   # change to your installed version
```

**`lli` not found**
```bash
which lli-17    # check the versioned binary
sudo apt install llvm-17
```

**Module verification failed**
This usually means the IR builder left an open basic block without a terminator (e.g. a `br` or `ret`). Check that every control-flow branch in `parser.y` emits a terminator instruction before switching insert points.

**`calc` produces no output**
Make sure your statements end with `;`. Expression statements without a semicolon are not emitted as `printf` calls in levels 008+.

---

## Requirements Summary (Quick Copy)

```bash
sudo apt update
sudo apt install flex bison g++ llvm-17 llvm-17-dev clang-17
```

```bash
# Verify
flex --version && bison --version && llvm-config-17 --version && g++ --version
```
