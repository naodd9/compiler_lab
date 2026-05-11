# Level 003 - AST Generation

## Description
This level generates an Abstract Syntax Tree (AST) from arithmetic expressions and evaluates it. Shows both the tree structure and computed value.

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
Input: 2+3
AST:
  Add
    Integer(2)
    Integer(3)
Value: 5
```

## Features
- Integer literals
- Addition (+), Subtraction (-)
- Multiplication (*), Division (/)
- Parentheses for grouping
- Unary minus
- AST visualization
- Direct AST evaluation

## Clean
```bash
make clean
```

## Note
Ctrl+D (Linux/Mac) or Ctrl+Z (Windows) to end input.