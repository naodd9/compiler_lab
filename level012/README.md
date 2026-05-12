# Level 012 - 1-Dimensional Arrays

## Description
This level adds 1-dimensional array definition and usage.

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
int arr[10];      // declare array of size 10
arr[0] = 5;       // assign value
arr[1] = arr[0] + 3;  // use in expression
```

## Examples
```
int nums[5];
nums[0] = 10;
nums[1] = 20;
nums[0] + nums[1];
```

## Features
- Array declaration: `int name[size];`
- Array element assignment: `arr[index] = value;`
- Array element access: `arr[index]`

## Clean
```bash
make clean
```

## Note
Ctrl+D (Linux/Mac) to end input.
