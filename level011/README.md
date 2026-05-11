# Level 011 - Functions with Arguments

## Description
This level adds function definition and function calls with arguments.

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
def add(a, b) {
    a + b;
}

add(3, 5);
```

## Examples
```
def double(x) {
    x * 2;
}

def max(a, b) {
    if (a > b) {
        a;
    } else {
        b;
    }
}

double(5);
max(10, 20);
```

## Features
- Function definition with parameters: `def name(a, b) { stmts }`
- Function call with arguments: `name(arg1, arg2)`
- Function parameters are local variables
- All Level 010 features

## Clean
```bash
make clean
```

## Note
Ctrl+D (Linux/Mac) to end input.