# Compiler Lab - Requirements & Usage

## Requirements

### Build Tools
- **Flex** (Lexical Analyzer) - tokenizes input
- **Bison** (Parser Generator) - generates parser
- **g++** (C++17 support) - compiles C++ code

### LLVM Version
- **LLVM 17** (uses `llvm-config-17`)
- If you have a different version, edit `Makefile` in each level:
  ```
  LLVM_CFG = llvm-config-17  →  llvm-config-15 (or your version)
  ```

---

## Installation - Linux (Ubuntu/Debian)

```bash
# Install all required packages
sudo apt update
sudo apt install flex bison g++ llvm-17 llvm-17-dev clang-17

# Verify installation
bison --version
flex --version
llvm-config-17 --version
g++ --version
```

### If llvm-config-17 is not found:
```bash
# Search for available LLVM versions
apt search llvm | grep llvm-config

# Or install with specific version
sudo apt install llvm-17-dev
```

---

## Installation - Linux (Fedora/RHEL/CentOS)

```bash
sudo dnf install flex bison gcc-c++ llvm-devel llvm-static

# For specific LLVM version (e.g., 17)
sudo dnf install llvm17-devel llvm17-static
```

---

## Installation - Linux (Arch/Manjaro)

```bash
sudo pacman -S flex bison gcc llvm17
```

---

## Installation - Windows

### Option 1: WSL (Windows Subsystem for Linux) - RECOMMENDED

1. Install WSL:
   ```powershell
   # Open PowerShell as Administrator
   wsl --install
   ```

2. Open Ubuntu terminal and install tools:
   ```bash
   sudo apt update
   sudo apt install flex bison g++ llvm-17 llvm-17-dev clang-17
   ```

3. Navigate to your project:
   ```bash
   cd /mnt/c/Users/YourName/Desktop/compiler
   ```

### Option 2: MSYS2/MinGW

1. Download MSYS2: https://www.msys2.org/

2. Open MSYS2 terminal and install:
   ```bash
   pacman -S flex bison mingw-w64-x86_64-gcc mingw-w64-x86_64-llvm17
   ```

3. Set PATH in MSYS2:
   ```bash
   export PATH="/mingw64/bin:$PATH"
   ```

### Option 3: Manual Build (Advanced)

1. Download LLVM from: https://releases.llvm.org/download.html
2. Install Flex and Bison from: https://www.gnu.org/software/flex/, https://www.gnu.org/software/bison/
3. Add all binaries to PATH

---

## Verify Installation

Run these commands to verify everything is installed:

```bash
# Should show version (e.g., 3.7.x)
flex --version

# Should show version (e.g., 3.8.x)
bison --version

# Should show version (e.g., 17.0.x)
llvm-config-17 --version

# Should show version 11+ or 13+
g++ --version
```

---

## Level Structure

| Level | Description | Features |
|-------|-------------|----------|
| 001 | Grammar Validation | Bison/Flex only |
| 002 | Direct Computation | Evaluate while parsing |
| 003 | AST Generation | Build and evaluate AST |
| 004 | LLVM IR | Generate IR, run with `lli-17` |
| 006 | Assembly Code | Generate `.s` with `llc-17` |
| 007 | Variables | Assignment statements |
| 008 | Control Flow | `if/else`, `while` |
| 009 | Short-circuit | `and`, `or` operators |
| 010 | Functions (no args) | `def foo() { }` |
| 011 | Function Args | `def add(a, b) { }` |
| 012 | 1D Arrays | `int arr[10];` |
| 013 | 2D Arrays | `int matrix[3][4];` |

---

## Usage

### Build a Level
```bash
cd levelXXX
make
```

### Run a Level
```bash
./calc
# Type code, press Ctrl+D to execute
```

### Generate IR Only (Level 004+)
```bash
make execute     # or: lli-17 output.ll
```

### Generate Assembly (Level 006+)
```bash
make asm         # llc-17 output.ll -o output.s
make link        # gcc -no-pie output.s -o calc
```

### Clean
```bash
make clean
```

### Clean All Levels
```bash
for level in level001 level002 level003 level004 level006 level007 level008 level009 level010 level011 level012 level013; do
  make -C $level clean
done
```

---

## Common Issues & Solutions

### `llvm-config-17: command not found`
```bash
# Ubuntu/Debian
sudo apt install llvm-17-dev

# Or check for other versions
ls /usr/bin/llvm-config-*
```

### `error: 'llvm::TargetRegistry' has no member`
Install LLVM development packages (not just runtime):
```bash
sudo apt install llvm-17-dev
```

### `bison: invalid character '*'`
Remove C-style comments (`/* */`) from between `%%` in parser.y. Only grammar rules go between `%%`.

### `Module verification failed: Basic Block does not have terminator`
Fixed by automatic `ret` instruction. Rebuild the level.

### `Parser error: syntax error` on valid code
Check that your lexer includes all necessary tokens (e.g., `DEF` keyword).

### `Error: variable 'x' used before assignment`
Make sure variables are assigned before use: `x = 5;`

---

## Examples

### Level 001-003 (No LLVM)
```
2+3
Syntax OK / 5
```

### Level 004-006 (LLVM IR)
```
2+3;
5
```

### Level 007 (Variables)
```
x = 5;
x + 3;
8
```

### Level 008 (Control Flow)
```
x = 5;
if (x > 3) {
    x;
}
5
```

### Level 009 (Short-circuit)
```
x = 5;
if (x > 3 and x < 10) {
    x;
}
5
```

### Level 010 (Functions)
```
def foo() {
    x = 10;
    x;
}
foo();
10
```

### Level 011 (Function Arguments)
```
def add(a, b) {
    a + b;
}
add(3, 5);
```

### Level 012 (Arrays)
```
int arr[5];
arr[0] = 10;
arr[0];
10
```

### Level 013 (2D Arrays)
```
int matrix[2][3];
matrix[0][0] = 5;
matrix[0][0];
5
```

---

## Debugging Level 010-013

### Level 010 (Functions)
**Common Issues:**
- `Error: variable 'def' used before assignment` → Lexer missing `DEF` keyword
- `Basic Block does not have terminator` → Functions need `ret` instruction (fixed automatically)

**Debug Steps:**
```bash
cd level010
make clean && make
./calc
# Test:
def foo() { x = 10; x; }
foo();
```

### Level 011 (Function Arguments)
**Common Issues:**
- `Error: variable 'a' used before assignment` → Function parameters not registered
- Missing comma token `,`

**Debug Steps:**
```bash
cd level011
make clean && make
./calc
# Test:
def add(a, b) { a + b; }
add(3, 5);
```

### Level 012 (1D Arrays)
**Common Issues:**
- `Error: array 'arr' not declared` → Use `int arr[size];` declaration
- Index out of bounds (not checked at runtime)

**Debug Steps:**
```bash
cd level012
make clean && make
./calc
# Test:
int arr[5];
arr[0] = 10;
arr[0];
```

### Level 013 (2D Arrays)
**Common Issues:**
- Same as Level 012
- Use `int matrix[rows][cols];` syntax

**Debug Steps:**
```bash
cd level013
make clean && make
./calc
# Test:
int matrix[2][3];
matrix[0][0] = 5;
matrix[0][0];
```

### General Debugging Commands
```bash
# View generated IR
cat output.ll

# Verify IR with lli
lli-17 output.ll

# Check bison conflicts
bison -d -v parser.y
cat parser.output

# Run with verbose lexer
flex -d lexer.l  # generates debug version
```

---

## Keyboard Shortcuts

| Action | Linux | Windows | Mac |
|--------|-------|---------|-----|
| End input | Ctrl+D | Ctrl+Z + Enter | Ctrl+D |
| Cancel | Ctrl+C | Ctrl+C | Ctrl+C |