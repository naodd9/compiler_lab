# Level 009 - Short-Circuit Boolean Expressions

## Description
This level adds short-circuit evaluation for boolean expressions using `and` and `or` operators.

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
if (a and b) { ... }
if (a or b) { ... }
if (a and b or c) { ... }
```

## Examples
```
x = 5;
y = 3;
if (x > 3 and y < 5) {
    x + y;
}

i = 10;
while (i > 0 and i != 5) {
    i;
    i = i - 1;
}
```

## Features
- Short-circuit `and` (stops if first operand is false)
- Short-circuit `or` (stops if first operand is true)
- All operators from Level 008
- Nested boolean expressions

## Clean
```bash
make clean
```

## Note
Ctrl+D (Linux/Mac) to end input.