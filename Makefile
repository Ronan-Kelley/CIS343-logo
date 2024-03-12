build: lex.yy.c gvlogo.tab.c gvlogo.tab.h
	gcc lex.yy.c gvlogo.tab.c -lSDL2 -lfl -lm

lex.yy.c: gvlogo.l
	flex gvlogo.l

gvlogo.tab.c: gvlogo.y
	bison -d gvlogo.y

gvlogo.tab.h: gvlogo.y
	bison -d gvlogo.y

clean:
	rm -f lex.yy.c gvlogo.tab.c gvlogo.tab.h a.out
