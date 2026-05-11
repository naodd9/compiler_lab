CXX       = g++

CXXFLAGS  = -Wall -Wextra -std=c++17

TARGET = calc

.PHONY: all run clean

all: $(TARGET)

parser.tab.c parser.tab.h: parser.y
	bison -d -v parser.y

lex.yy.c: lexer.l parser.tab.h
	flex lexer.l

$(TARGET): parser.tab.c lex.yy.c
	$(CXX) $(CXXFLAGS) -o $@ parser.tab.c lex.yy.c -ll

run: $(TARGET)
	./$(TARGET)

clean:
	rm -f $(TARGET) parser.tab.c parser.tab.h lex.yy.c parser.output