CXX       = g++
LLVM_CFG  = llvm-config-17

CXXFLAGS  = -Wall -Wextra -std=c++17 \
            $(shell $(LLVM_CFG) --cxxflags) \
            -Wno-unused-parameter \
            -Wno-unused-function

LDFLAGS   = $(shell $(LLVM_CFG) --ldflags)
LLVM_LIBS = $(shell $(LLVM_CFG) --libs core support analysis) \
            $(shell $(LLVM_CFG) --system-libs)

TARGET = calc

.PHONY: all run execute clean

all: $(TARGET)

# ── 1. Run Bison ─────────────────────────────────────────────
parser.tab.c parser.tab.h: parser.y
	bison -d -v parser.y

# ── 2. Run Flex ──────────────────────────────────────────────
lex.yy.c: lexer.l parser.tab.h
	flex lexer.l

# ── 3. Compile & link ─────────────────────────────────────────
#   -x c++ : treat the Flex-generated .c as C++ (needed for LLVM headers)
$(TARGET): parser.tab.c lex.yy.c symtab.h llvm_includes.h
	$(CXX) $(CXXFLAGS) -x c++ -o $@ parser.tab.c lex.yy.c \
	    $(LDFLAGS) $(LLVM_LIBS)

# ── Convenience targets ────────────────────────────────────────
run: $(TARGET)
	./$(TARGET)

execute: output.ll
	lli-17 output.ll

clean:
	rm -f $(TARGET) parser.tab.c parser.tab.h lex.yy.c \
	      parser.output output.ll
