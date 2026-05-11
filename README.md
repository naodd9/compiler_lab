# Compiler Lab 

## Requirements

## we should run and debug starting from level 10 till the end

### Build Tools
- **Flex** (Lexical Analyzer) - tokenizes input
- **Bison** (Parser Generator) - generates parser
- **g++** (C++17 support) - compiles C++ code

### LLVM Version
- **LLVM 17** (uses `llvm-config-17`)
- If you have a different version, edit `Makefile` in each level:
  ```
  LLVM_CFG = llvm-config-17  →  llvm-config-15 (or your version)
  ```

---

## Installation - Linux (Ubuntu/Debian)

```bash
# Install all required packages
sudo apt update
sudo apt install flex bison g++ llvm-17 llvm-17-dev clang-17

# Verify installation
bison --version
flex --version
llvm-config-17 --version
g++ --version
```


## Verify Installation

Run these commands to verify everything is installed:

```bash
# Should show version (e.g., 3.7.x)
flex --version

# Should show version (e.g., 3.8.x)
bison --version

# Should show version (e.g., 17.0.x)
llvm-config-17 --version

# Should show version 11+ or 13+
g++ --version
```

---

## Level Structure

| Level | Description | Features |
|-------|-------------|----------|
| 001 | Grammar Validation | Bison/Flex only |
| 002 | Direct Computation | Evaluate while parsing |
| 003 | AST Generation | Build and evaluate AST |
| 004 | LLVM IR | Generate IR, run with `lli-17` |
| 006 | Assembly Code | Generate `.s` with `llc-17` |
| 007 | Variables | Assignment statements |
| 008 | Control Flow | `if/else`, `while` |
| 009 | Short-circuit | `and`, `or` operators |
| 010 | Functions (no args) | `def foo() { }` |
| 011 | Function Args | `def add(a, b) { }` |
| 012 | 1D Arrays | `int arr[10];` |
| 013 | 2D Arrays | `int matrix[3][4];` |

---


## Keyboard Shortcuts

| Action | Linux | Windows | Mac |
|--------|-------|---------|-----|
| End input | Ctrl+D | Ctrl+Z + Enter | Ctrl+D |
| Cancel | Ctrl+C | Ctrl+C | Ctrl+C |
