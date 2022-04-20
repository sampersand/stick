#pragma once

struct token {
	enum {
		TOK_LABEL,                // :string
		TOK_DUPLICATE,            // ~number
		TOK_PUSH_IMMEDIATE,       // $string
		TOK_DELETE,               // !number

		TOK_ADD,                  // +
		TOK_CONCAT,               // .
		TOK_SUB,                  // -
		TOK_MUL,                  // *
		TOK_REPEAT,               // x
		TOK_DIV,                  // /
		TOK_MOD,                  // %
		TOK_POW,                  // ^

		TOK_JMP_call,             // Cstring
		TOK_JMP_ZERO,             // Zstring
		TOK_JMP_NONZERO,          // Nstring
		TOK_JMP,                  // Jstring

		TOK_PRINT,                // P
		TOK_INPUT,                // I
		TOK_RETURN,               // R
	} kind;

	char *string; // is NULL for types not expecting it
};

struct token parse_token(const char **);