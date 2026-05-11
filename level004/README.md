# Level 004 - LLVM IR Generation

## Description
This level generates LLVM IR (Intermediate Representation) from arithmetic expressions. Output can be run with the `lli` tool or executed directly via JIT.

## Build
```bash
make
```

## Run
```bash
./calc
```

Type arithmetic expressions and press Enter. Press Ctrl+D to execute.

## Execute IR Only
```bash
make execute
```
or
```bash
lli-17 output.ll
```

## Examples
```
2+3        → outputs 5
5 * 10    → outputs 50
(2 + 3) * 4  → outputs 20
```

## Features
- Integer literals
- Addition (+), Subtraction (-)
- Multiplication (*), Division (/)
- Parentheses for grouping
- Unary minus
- LLVM IR generation
- JIT execution
- Output to `output.ll`

## Generated IR
The compiler generates LLVM IR that can be viewed in `output.ll`:
```llvm
define i32 @main() {
entry:
  %addtmp = add i32 2, 3
  call i32 (ptr, ...) @printf(ptr @"%d\n", i32 %addtmp)
  ret i32 0
}
```

## Clean
```bash
make clean
```

## Note
- Ctrl+D (Linux/Mac) or Ctrl+Z (Windows) to end input
- Uses LLVM 17 - adjust llvm-config version if needed