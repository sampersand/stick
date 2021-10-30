#include "token.h"

enum opcode {
	OP_ADD,                  // +
	OP_CONCAT,               // .
	OP_SUB,                  // -
	OP_MUL,                  // *
	OP_REPEAT,               // x
	OP_DIV,                  // /
	OP_MOD,                  // %
	OP_POW,                  // ^

	op_pop

	enum {
		TOK_FUNC,                 // ;string
		TOK_LABEL,                // :string
		TOK_PUSH_STACK,           // ~number
		TOK_PUSH_IMMEDIATE,       // $string
		TOK_POP,                  // v
OP

		TOK_JMP_call,             // Cstring
		TOK_JMP_ZERO,             // Zstring
		TOK_JMP_NONZERO,          // Nstring
		TOK_JMP,                  // Jstring

		TOK_PRINT,                // P
		TOK_INPUT,                // I
	} kind;

	char *string; // is NULL for types not expecting it
};


struct compiler {
	int nlabels, nconsts, proglen;
	struct label { char *name, is_function; } *labels;
	struct bytecode { } *program;
};
