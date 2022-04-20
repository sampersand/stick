use crate::value::{Value, ParseError};

#[derive(Debug)]
pub struct Stream<'s>(std::str::Split<'s, fn(char) -> bool>, bool);

impl<'s> Stream<'s> {
	pub fn new(stream: &'s str) -> Self {
		Self(stream.split(char::is_whitespace), false)
	}

	pub fn lineno(&self) -> usize {
		0
	}

	pub fn value(mut self) -> Result<Value, ParseError> {
		let mut block = Vec::new();

		while let Some(value) = Value::parse(&mut self)? {
			block.push(value);
		}

		Ok(Value::Block(block.into()))
	}
}

impl<'s> Iterator for Stream<'s> {
	type Item = &'s str;

	fn next(&mut self) -> Option<&'s str> {
		if self.1 {
			return None;
		}

		match self.0.next() {
			Some("__END__") => { self.1 = true; None },
			Some("") => self.next(),
			other => other
		}
	}
}
