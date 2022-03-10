#include <stdio.h>
#include <ctype.h>
#include <stdlib.h>
#include <string.h>

typedef struct _expr {
	enum { OP, VAR, NUM, STR, LAMBDA } kind;

	union {
		const char *op;
		long long num;
		char *str;

		struct {
			int len;
			struct _expr *exprs;
		} lambda;
	};
} expr;

#define abort_msg(...) do { fprintf(stderr, __VA_ARGS__); exit(1); } while(0)

#ifndef STACKSIZE
#define STACKSIZE 100000
#endif
expr *stack[STACKSIZE], *stack2[STACKSIZE];
int top, top2;

void push(expr *e) {
	if (top == STACKSIZE) abort_msg("stack overflow");
	stack[top++] = e;
}

expr *pop() {
	if (!top) abort_msg("stack underflow");
	return stack[--top];
}

struct {
	int len, cap;
	struct var { const char *name; expr *value; } *vars;
} vars;

expr *lookup(const char *name) {
	for (int i = 0; i < vars.len; ++i)
		if (!strcmp(name, vars.vars[i].name)) return vars.vars[i].value;
	return 0;
}

void store(const char *name, expr *value) {
	for (int i = 0; i < vars.len; ++i)
		if (!strcmp(name, vars.vars[i].name)) {
			vars.vars[i].value = value;
			return;
		}

	if (vars.len == vars.cap)
		vars.vars = realloc(vars.vars, sizeof(struct var) * (vars.cap = vars.cap * 2 + 1));

	vars.vars[vars.len].name = name;
	vars.vars[vars.len++].value = value;
}


long long tonum(expr *e) {
	if (e->kind == NUM) return e->num;
	if (e->kind == STR) return strtoll(e->str, NULL, 10);
	abort_msg("cannot convert %d to a string", e->kind);
}

expr *fromnum(long long num) {
	expr *e = malloc(sizeof(expr));
	e->kind = NUM;
	e->num = num;
	return e;
}

void dump(expr *e);
void run(expr *e) {
	expr *a, *b, *c;
	if (e->kind != OP) {
		push(e); // memory leak for strings ftw lol
		dump(e);fflush(stdout);
		return;
	}

	if ((a = lookup(e->op))) {
		push(a);
		return;
	}

	if (!strcmp(e->op, "=")) {
		store(e->op, pop());
		return;
	}

	switch (e->op[0]) {
	case '+':
		printf("spot1\n");fflush(stdout);
		a = pop();
		b = pop();
		printf("spot1\n");fflush(stdout);
		push(fromnum(tonum(a) + tonum(b)));
		break;

	case 'P':
		a = pop();
		if (a->kind == NUM) printf("%lld", a->num);
		else if (a->kind == STR) printf("%s", a->str);
		else abort_msg("cannot convert %d to a string", a->kind);
		break;
		fflush(stdout);
	}
}

void dump(expr *e) {
	switch (e->kind) {
	case OP: printf("op(%s)", e->op); break;
	case VAR: printf("var(%s)", e->op); break;
	case NUM: printf("num(%lld)", e->num); break;
	case STR: printf("str(%s)", e->str); break;
	case LAMBDA:
		printf("lambda{");
		for (int i = 0; i < e->lambda.len; ++i)
			printf(" "), dump(&e->lambda.exprs[i]);
		printf(" }");
		break;
	}
}

	const char *WHITESPACE = " \r\n\f\t";

void parse_tok(char *tok, expr *dst) {
	char c;
	if (isdigit(c = tok[0])) {
		dst->kind = NUM;
		dst->num = strtoll(tok, NULL, 10);
		return;
	}

	if (c == '\'' || c == '\"') {
		// todo: spaces?
		abort();
	}

	if (c == '{') {
		int cap = 8;
		dst->kind = LAMBDA;
		dst->lambda.len = 0;
		dst->lambda.exprs = malloc(sizeof(expr)*cap);
		dst->lambda.exprs[0].kind = 2;

		while (strcmp("}", tok = strtok(NULL, WHITESPACE))) {
			if (cap == dst->lambda.len)
				dst->lambda.exprs = realloc(dst->lambda.exprs, sizeof(expr) * (cap *= 2));

			parse_tok(tok, &dst->lambda.exprs[dst->lambda.len++]);
		}

		return;
	}

	if (tok[0] == '(') {
		// while (strcmp(")", strtok(NULL, WHITESPACE)));
		abort();
		// return parse_tok();
	}

	if (tok[0] == '/') dst->kind = VAR, ++tok;
	else dst->kind = OP;

	dst->op = tok;
}

expr *parse() {
	char *tok = strtok(NULL, WHITESPACE);
	if (!tok) return 0;
	expr *e = malloc(sizeof(expr));
	parse_tok(tok, e);
	return e;
}

int main() {
	// char *s = strdup("begin\nadd { + } def\n1 2 add P");
	char *s = strdup("begin\na 2 + P");

	strtok(s, "\n");
	expr *e;
	while ((e = parse()))
		run(e);
}

/*
@fib
Jfoo
push 1
ret
:foo
push 2
ret

main { 1 2 3 } DEF
	0 # a = 0
	0 # b = 0
	{ dup 10 < }
	{1 + } while
	pop
	print
*/

/*
	if (e->kind == VAR) {
		if (!(a = lookup(e->op)))
			abort_msg("undefined variable '%s'", e->op);
		else
			return push(a), (void) 0;
	}

*/
