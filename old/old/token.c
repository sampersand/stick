#include <ctype.h>
#include <string.h>
#include "shared.h"
#include "token.h"


char *parse_string(const char **stream) {
	while (isspace(**stream))
		++*stream;

	const char **start = stream;

	if (**stream == '\'' || **stream == '\"') {
		char quote = *(*stream++);

		while (*++*stream != quote)
			if (!**stream)
				die("missing closing quote");
	} else {
		while (isalnum(**stream) || **stream == '_')
			++*stream;
	}

	return strndup(*start, stream - start);
}

struct token parse_token(const char **stream) {
	struct token token;
	char chr;

	switch (chr = *++*stream)	 {
	case '#':
		while (**stream != '\n' && **stream != '\0')
			++*stream;
		// fallthrough
	case ' ':
	case '\n':
	case '\r':
	case '\t':
	case '\v':
	case '\f':
		return parse_token(stream);

#define OPERATOR(sym, kind_) case sym: token.kind = kind_; break;
	OPERATOR('+', TOK_ADD)
	OPERATOR('.', TOK_CONCAT)
	OPERATOR('-', TOK_SUB)
	OPERATOR('*', TOK_MUL)
	OPERATOR('x', TOK_REPEAT)
	OPERATOR('/', TOK_DIV)
	OPERATOR('%', TOK_MOD)
	OPERATOR('^', TOK_POW)

#define STRING_OP(sym, kind_) case sym: token.kind = kind_; token.string = parse_string(stream); break;
	STRING_OP(':', TOK_LABEL)
	STRING_OP('~', TOK_PUSH_STACK)
	STRING_OP('$', TOK_PUSH_IMMEDIATE)
	STRING_OP('!', TOK_POP)
	STRING_OP('C', TOK_CALL)
	STRING_OP('Z', TOK_JMP_ZERO)
	STRING_OP('N', TOK_JMP_NONZERO)
	STRING_OP('J', TOK_JMP)

	STRING_OP('P', TOK_PRINT)
	STRING_OP('I', TOK_INPUT)
	STRING_OP('I', TOK_RETURN)

	default:
		die("unknown token start '%c'", chr);
	}

	return token;
}
