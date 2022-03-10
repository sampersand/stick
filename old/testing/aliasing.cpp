#include <stdlib.h>
#include <stdio.h>
typedef size_t integer;
typedef long long ll;

template<typename T>
struct foo {
	integer x;
	int y;
	T z;
	void (*ll)(int y, char *z);
};
	// void (*llm)(int y, char *z) = 0x;

struct stringy {
	char *ptr;
	long long len;
};

struct stringy s = { "foo", 3 };

stringy *return_stringy(){
	stringy *s2 = &s;
	return s2;
}

extern int fooey;
int bar;
extern integer doit(int x);

template<typename T>
foo<T> doit2(integer z) {
	bool x = true;
	return (foo<T>) { doit(z), 3, x };
}

integer doit(int x, int y) { return x % y; }

int yuppero() { return 3; }

struct lc_list {
	void *p;
	bool l;
	ll n, c;
};


struct mathop {
	ll kind;
	union {
		struct { ll num; } *mop;
		void *other;
	};
};

int lel(){return 1;}
int heh() { return 2; }
int nop() { return 3; }
ll yup(struct lc_list *l, ll x) {
	return lel() ? heh() : nop();
	// xx = x + yy;
	// return xx;
	// return (unsigned) x() < x();
}

// int index_into_it(struct )

int lol1(int l, int y) {
	while (doit(l))
		l ++;
	// int q = l;
	// if (l == 1) 
		// q = y;
	return y;
	// return l - y;
}

int main() {
	foo<bool> f = doit2<bool>(3);

	int l = 39192;
	printf("%d %d", f.x, f.y + fooey, l);
}
