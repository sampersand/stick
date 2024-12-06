#pragma once

#include <variant>
#include <string>

using integer = long long;
using std::string;

class Stringy {
	std::variant<integer, string> value;

public:

	Stringy(integer i) : value(i) {}
	Stringy(string s) : value(s) {}

	operator integer () const;
	operator string () const;
};
