#include "stringy.hpp"

#include <sstream>

Stringy::operator integer() const {
	if (const integer *n = std::get_if<integer>(&value))
		return *n;

	integer n;
	std::stringstream(std::get<string>(value)) >> n;
	return n;
}

Stringy::operator string() const {
	if (const string *s = std::get_if<string>(&value))
		return *s;

	return std::to_string(std::get<integer>(value));
}
