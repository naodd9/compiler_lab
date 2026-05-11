# Level 006 - Assembly Code Generation

## Description
This level generates x86-64 assembly code from arithmetic expressions. The output can be assembled and linked into an executable.

## Build
```bash
make
```

## Run
```bash
./calc
```

Type arithmetic expressions and press Enter. Press Ctrl+D to generate assembly.

## Assemble and Execute
```bash
make execute
```
or manually:
```bash
llc-17 output.ll -o output.s
gcc -no-pie output.s -o calc

./calc
```

## Examples
```
Input: 2+3
Output: x86-64 assembly in output.s
Execute: ./calc → outputs 5
```

## Features
- Integer literals
- Addition (+), Subtraction (-)
- Multiplication (*), Division (/)
- Parentheses for grouping
- Unary minus
- x86-64 assembly output
- Direct system call generation

## Generated Assembly
The compiler generates x86-64 assembly that can be viewed in `output.s`:
```asm
    .text
    .global main
main:
    subq    $8, %rsp
    movl    $2, %eax
    addl    $3, %eax
    ...
```

## Requirements
- GCC with x86-64 support
- LLVM 17 with native target enabled

## Clean
```bash
make clean
```

## Note
- Ctrl+D (Linux/Mac) or Ctrl+Z (Windows) to end input
- Uses `-no-pie` flag for compatibility