all: parser

clean:
	rm bison.hpp bison.cpp parser lex.cpp

bison.cpp: bison.y
	/usr/bin/bison -d -o $@ $^

lex.cpp: lex.l
	flex -o $@ $^

only: bison.cpp lex.cpp
	g++ -g -o $@ $^

parser: bison.cpp lex.cpp
	g++ -g -o $@ $^
