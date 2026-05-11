# Level 013 - Multi-Dimensional Arrays

## Description
This level adds multi-dimensional (2D) array definition and usage.

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
int arr[10];           // 1D array of size 10
int matrix[3][4];     // 2D array (3 rows, 4 columns)

matrix[0][1] = 5;     // assign value
matrix[1][2] = matrix[0][1] + 3;  // use in expression
```

## Examples
```
int matrix[2][3];
matrix[0][0] = 1;
matrix[0][1] = 2;
matrix[0][2] = 3;
matrix[1][0] = 4;
matrix[1][1] = 5;
matrix[1][2] = 6;

matrix[0][0];
matrix[1][2];
```

## Features
- 1D array declaration: `int name[size];`
- 2D array declaration: `int name[rows][cols];`
- Array element assignment for both 1D and 2D
- Array element access for both 1D and 2D
- All Level 012 features

## Clean
```bash
make clean
```

## Note
Ctrl+D (Linux/Mac) to end input.