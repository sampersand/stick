use crate::{Stream, Environment, Error, BuiltinFn};
use std::fmt::{self, Display, Formatter};
use std::rc::Rc;
use std::cell::RefCell;

type Integer = i64;

#[derive(Debug, Clone, PartialEq, Eq)]
pub enum Value {
	Integer(Integer),
	String(Rc<str>),
	Array(Rc<RefCell<Vec<Value>>>),
	Variable(Rc<str>),
	Block(Rc<[Value]>),
	BuiltinFn(&'static BuiltinFn)
}

impl Default for Value {
	fn default() -> Self {
		Self::Integer(0)
	}
}

impl Display for Value {
	fn fmt(&self, f: &mut Formatter) -> fmt::Result {
		match self {
			Self::Integer(integer) => write!(f, "{}", integer),
			Self::String(string) => write!(f, "{}", string),
			Self::Array(array) => write!(f, "{:?}", array),
			Self::Variable(variable) => write!(f, "<variable {}>", variable),
			Self::Block(block) => write!(f, "<block {:?}>", block),
			Self::BuiltinFn(builtinfn) => write!(f, "<builtin {}>", builtinfn.name()),
		}
	}
}

impl Value {
	pub const fn typename(&self) -> &'static str {
		match self {
			Self::Integer(_) => "scalar",
			Self::String(_) => "scalar",
			Self::Array(_) => "array",
			Self::Variable(_) => "variable",
			Self::Block(_) => "block",
			Self::BuiltinFn(_) => "builtinfn",
		}
	}

	pub fn run(&self, env: &mut Environment) -> Result<(), Error> {
	if let Self::Variable(var) = self {
			if let Some(res) = env.lookup(&var) {
				res.clone().call(env)
			} else if let Some(missing) = env.lookup("<missing>") {
				let missing = missing.clone();
				env.push(var.to_string().into());
				missing.call(env)
			} else {
				Err(Error::UnknownVariable(var.to_string()))
			}
		} else {
			env.push(self.clone());
			Ok(())
		}
	}

	pub fn call(&self, env: &mut Environment) -> Result<(), Error> {
		match self {
			Self::BuiltinFn(builtin) => builtin.call(env),
			Self::Block(block) => block.iter().try_for_each(|ele| ele.run(env)),
			Self::String(string) =>
				env.lookup(&string)
					.ok_or_else(|| Error::UnknownVariable(string.to_string()))?
					.clone()
					.call(env),
			_ => Err(Error::CannotCall(self.typename()))
		}
	}

	pub fn to_integer(&self) -> Integer {
		match self {
			Self::Integer(integer) => *integer,
			Self::String(string) => 
				string
					.trim_start_matches(char::is_whitespace)
					.trim_end_matches(|c: char| !c.is_ascii_digit())
					.parse::<Integer>()
					.unwrap_or(0),
			Self::Array(array) => array.borrow().len() as Integer,
			Self::Variable(var) => panic!("attempted to convert variable '{}' to an integer", var),
			Self::Block(block) => block.as_ptr() as Integer,
			Self::BuiltinFn(builtin) => builtin as *const _ as Integer,
		}
	}

	pub fn to_boolean(&self) -> bool {
		match self {
			Self::Integer(n) => *n != 0,
			Self::String(s) => !s.is_empty() && &**s != "0",
			_ => true
		}
	}
}

impl From<Integer> for Value {
	fn from(integer: Integer) -> Self {
		Self::Integer(integer)
	}
}

impl From<bool> for Value {
	fn from(boolean: bool) -> Self {
		Self::Integer(if boolean { 1 } else { 0 })
	}
}

impl From<String> for Value {
	fn from(string: String) -> Self {
		Self::String(Rc::from(string))
	}
}

impl From<char> for Value {
	fn from(character: char) -> Self {
		Self::from(character.to_string())
	}
}

impl From<&'static str> for Value {
	fn from(string: &'static str) -> Self {
		Self::from(string.to_string())
	}
}

impl From<Rc<str>> for Value {
	fn from(string: Rc<str>) -> Self {
		Self::String(string)
	}
}

impl From<Vec<Value>> for Value {
	fn from(array: Vec<Value>) -> Self {
		Self::Array(Rc::new(array.into()))
	}
}

#[derive(Debug, Clone, PartialEq, Eq)]
pub enum ParseError {
	MissingRightBrace(usize),
	UnexpectedRightBrace(usize),
	MissingEndOfComment(usize)
}

impl Value {
	pub fn parse(stream: &mut Stream) -> Result<Option<Self>, ParseError> {
		let lineno = stream.lineno();

		match stream.next() {
			Some("(") => {
				let mut i = 1;
				while i != 0 {
					match stream.next() {
						Some("(") => i += 1,
						Some(")") => i -= 1,
						None => return Err(ParseError::MissingEndOfComment(lineno)),
						_ => {}
					}
				}
				Self::parse(stream)
			},
			Some("}") => Err(ParseError::UnexpectedRightBrace(lineno)),
			Some("{") => {
				let mut block = Vec::new();

				loop {
					match Self::parse(stream) {
						Ok(Some(value)) => block.push(value),
						Ok(None) => return Err(ParseError::MissingRightBrace(lineno)),
						Err(ParseError::UnexpectedRightBrace(_)) => break,
						Err(other) => return Err(other)
					}
				}

				Ok(Some(Self::Block(Rc::from(block))))
			},
			Some(s) => {
				// integer literal
				if let Ok(integer) = s.parse::<Integer>() {
					return Ok(Some(Self::Integer(integer)))
				}

				// string literal
				if let Some(string) = s.strip_prefix("\"").and_then(|s| s.strip_suffix("\"")) {
					return Ok(Some(Self::String(Rc::from(string
						.replace('•', " ")
						.replace("\\s", " ")
						.replace("\\n", "\n")
						.replace("\\t", "\t")
						.replace("\\0", "\0")
						// todo: replace `\x`.
					))))
				}

				// shorthand for strings
				if let Some(variable) = s.strip_prefix(":") {
					return Ok(Some(Self::from(variable.to_owned())))
				}

				Ok(Some(Self::Variable(Rc::from(s.to_string()))))
			},
			None => Ok(None)
		}
	}
}
