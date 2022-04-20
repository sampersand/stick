#include <stdio.h>
#include <string.h>

typedef long long ll;
// extern ll push(ll);
// extern ll pop(void);


char *toptr(ll val){
	static char ptrbuf[40];
	snprintf(ptrbuf, 40, "%lld", val);
	return strdup(ptrbuf);
}

extern ll strtoll(char *, char **, int);
ll doit(char *x) {
	return strtoll(x, NULL, 10);
}

ll globals[100000], *idx = globals;

void push(ll value) {
	*idx++ = value;
}

ll pop() {
	return *--idx;
}

ll add() {
	ll a = pop();
	return pop() + a;
}

int main() {
	push(34);
	push(45);

	printf("%lld\n", add());
}