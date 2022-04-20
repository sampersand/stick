static struct foo *yup;

static struct foo *yupp(){
	return yup;
}

struct foo*lol() {
	return yupp();
}
// 
// struct mathop {
// 	long long kind;
// 	union {
// 		struct { long long num; } *mop;
// 		void *other;
// 		struct { int a, b, c, d; } what;
// 	};
// };
// 
// extern __attribute__((noreturn)) exit();
// void leave() {
// 	exit(1);
// }
// 
// long long lol(long long *x){
// 	return x[1];
// }
// struct mathop *foo(int x) {
// 	struct mathop mo;
// 	mo.kind = 34;
// 	if (x==0) {
// 		mo.mop = 1;
// 	} else if (x==2) mo.other = 2; else if (x==3) mo.what.a=3;
// 	return 0;
// }
