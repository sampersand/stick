use crate::value::Value;
use std::collections::HashMap;

#[derive(Debug)]
pub struct Environment {
	vars: HashMap<String, Value>,
	stack: Vec<Value>,
	stack2: Vec<Value>
}

impl Default for Environment {
	fn default() -> Self {
		Self::new()
	}
}

impl Environment {
	pub fn new() -> Self {
		Self::with_capacity(0)
	}

	pub fn with_capacity(cap: usize) -> Self {
		Self {
			vars: crate::builtinfn::default_vars(),
			stack: Vec::with_capacity(cap),
			stack2: Vec::new()
		}
	}
}

impl Environment {
	pub fn stack(&self) -> &[Value] {
		&self.stack
	}

	pub fn stack2(&self) -> &[Value] {
		&self.stack2
	}

	pub fn lookup(&self, var: &str) -> Option<&Value> {
		self.vars.get(var)
	}

	pub fn assign(&mut self, var: &str, value: Value) {
		self.vars.insert(var.to_owned(), value);
	}

	pub fn unassign(&mut self, var: &str) {
		self.vars.remove(var);
	}

	pub fn push(&mut self, value: Value) {
		self.stack.push(value)
	}

	pub fn pop(&mut self) -> Option<Value> {
		self.stack.pop()
	}

	pub fn popn(&mut self, index: usize) -> Option<Value> {
		self.correct(index).map(|index| self.stack.remove(index))
	}

	fn correct(&self, index: usize) -> Option<usize> {
		if index <= self.stack.len() {
			Some(self.stack.len() - index)
		} else {
			None
		}
	}

	pub fn nth(&self, index: usize) -> Option<&Value> {
		self.correct(index).map(|idx| &self.stack[idx])
	}

	pub fn push2(&mut self, value: Value) {
		self.stack2.push(value)
	}

	pub fn pop2(&mut self) -> Option<Value> {
		self.stack2.pop()
	}
}
