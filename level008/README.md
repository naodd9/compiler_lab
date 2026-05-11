# Level 008 - Control Flow (if/while)

## Description
This level adds control flow statements (if-then-else, while) with boolean expressions. Variables and arithmetic expressions are also supported.

## Build
```bash
make
```

## Run
```bash
./calc
```

## Syntax
```
x = 5;
if (x > 3) {
    x = x - 1;
}
while (x > 0) {
    x = x - 1;
}
```

## Examples
```
x = 5;
if (x > 3) {
    x + 1;
}

i = 10;
while (i > 0) {
    i;
    i = i - 1;
}
```

## Features
- Variable assignment: `x = 5;`
- If-then: `if (cond) { stmts }`
- If-then-else: `if (cond) { stmts } else { stmts }`
- While loop: `while (cond) { stmts }`
- Comparison operators: `>`, `<`, `>=`, `<=`, `==`, `!=`
- All arithmetic from Level 004

## Clean
```bash
make clean
```

## Note
Ctrl+D (Linux/Mac) to end input.