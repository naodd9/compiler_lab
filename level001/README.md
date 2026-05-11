# Level 001 - Grammar Validation

## Description
This level only validates the grammar structure of arithmetic expressions. No code generation or execution is performed.

## Build
```bash
make
```

## Run
```bash
./calc
```

Type arithmetic expressions and press Enter. Press Ctrl+D to parse.

## Examples
```
2+3        → Syntax OK
5 * 10    → Syntax OK
(2 + 3)   → Syntax OK
-5 + 3    → Syntax OK
```

## Features Validated
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