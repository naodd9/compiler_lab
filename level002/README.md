# Level 002 - Direct Computation

## Description
This level computes arithmetic expressions directly during parsing. Results are printed immediately.

## Build
```bash
make
```

## Run
```bash
./calc
```

Type arithmetic expressions and press Enter. Press Ctrl+D to compute.

## Examples
```
2+3        → 5
5 * 10    → 50
(2 + 3) * 4  → 20
-5 + 3    → -2
10 / 3    → 3
```

## Features
- Integer literals
- Addition (+), Subtraction (-)
- Multiplication (*), Division (/)
- Parentheses for grouping
- Unary minus

## Clean
```bash
make clean
```

## Note
Ctrl+D (Linux/Mac) or Ctrl+Z (Windows) to end input.