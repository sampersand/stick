use crate::{Environment, Value, Error};
use std::fmt::{self, Debug, Formatter};

#[derive(Clone, Copy)]
pub struct BuiltinFn {
	name: &'static str,
	func: fn(&mut Environment) -> Result<(), Error>
}

impl Eq for BuiltinFn {}
impl PartialEq for BuiltinFn {
	fn eq(&self, rhs: &Self) -> bool {
		self.name == rhs.name
	}
}

impl Debug for BuiltinFn {
	fn fmt(&self, f: &mut Formatter) -> fmt::Result {
		f.debug_tuple("BuiltinFn").field(&self.name).finish()
	}
}

impl BuiltinFn {
	pub const fn name(&self) -> &'static str {
		self.name
	}

	pub fn call(&self, env: &mut Environment) -> Result<(), Error> {
		match (self.func)(env) {
			Err(Error::Return(0)) => Ok(()),
			Err(Error::Return(n)) => Err(Error::Return(n-1)),
			other => other
		}
	}
}

pub fn default_vars() -> std::collections::HashMap<String, Value> {
	macro_rules! fns {
		($env:ident; $($name:literal => $body:expr),* $(,)?) => {
			let mut h = std::collections::HashMap::new();
			$(
				h.insert($name.to_owned(), Value::BuiltinFn(&BuiltinFn {
					name: $name,
					func: |$env| {
						#[allow(unused_macros)]
						macro_rules! pop {
							() => ($env.pop().ok_or(Error::PoppedFromEmptyStack)?);
							($n:expr) => ($env.popn($n).ok_or(Error::PoppedFromEmptyStack)?);
						}

						#[allow(unused_macros)]
						macro_rules! popi {
							() => (pop!().to_integer());
							($n:expr) => (pop!($n).to_integer());
						}

						#[allow(unused_macros)]
						macro_rules! pops {
							() => (pop!().to_string());
							($n:expr) => (pop!($n).to_string());
						}

						#[allow(unused_macros)]
						macro_rules! push {
							($s:expr) => ({ let x = $s; $env.push(x) });
						}

						#[allow(unused_macros)]
						macro_rules! pushs {
							($s:expr) => (push!(Value::String($s.into())));
						}

						#[allow(unused_macros)]
						macro_rules! pushi {
							($i:expr) => (push!(Value::Integer($i)));
						}

						#[allow(unused_macros)]
						macro_rules! pushb {
							($b:expr) => (push!(Value::Integer(if $b { 1 } else { 0 })));
						}

						$body;

						#[allow(unreachable_code)]
						Ok(())
					}
				}));
			)*
			h
		}
	}

	fns! { env;
		"dumpa" => println!("stacka={:?}", env.stack()),
		"dumpb" => println!("stackb={:?}", env.stack2()),
		"print" => print!("{}", pop!()),
		"println" => println!("{}", pop!()),
		"quit" => std::process::exit(popi!() as i32),

		"+" => pushi!(popi!(2) + popi!()),
		"-" => pushi!(popi!(2) - popi!()),
		"*" => pushi!(popi!(2) * popi!()),
		"%" => pushi!(popi!(2) % popi!()),
		"/" => pushi!(popi!(2) / popi!()),
		"^" => pushi!(popi!(2).pow(popi!() as u32)),
		"<" => pushb!(popi!(2) < popi!()),
		"≤" => pushb!(popi!(2) <= popi!()),
		">" => pushb!(popi!(2) > popi!()),
		"≥" => pushb!(popi!(2) >= popi!()),
		"=" => pushb!(popi!(2) == popi!()),
		"≠" => pushb!(popi!(2) != popi!()),

		"." => pushs!(pops!(2) + pops!().as_str()),
		"x" => pushs!(pops!(2).repeat(popi!() as usize)),
		"lt" => pushb!(pops!(2) < pops!()),
		"le" => pushb!(pops!(2) <= pops!()),
		"gt" => pushb!(pops!(2) > pops!()),
		"ge" => pushb!(pops!(2) >= pops!()),
		"eq" => pushb!(pops!(2) == pops!()),
		"ne" => pushb!(pops!(2) != pops!()),

		"if" => {
			let (iff, ift, cond) = (pop!(), pop!(), pop!());
			if cond.to_boolean() {
				ift.call(env)?;
			} else {
				iff.call(env)?;
			}
		},
		"while" => {
			let (body, cond) = (pop!(), pop!());

			while {cond.call(env)?; pop!().to_boolean()} {
				body.call(env)?;
			}
		},
		"ret" => return Err(Error::Return(popi!() as usize)),
		"throw" => return Err(Error::Custom(pops!())),

		"def" => { let (val, name) = (pop!(), pops!()); env.assign(&name, val) },
		"undef" => { let what = pops!(); env.unassign(&what); },

		"!" => pushb!(!pop!().to_boolean()),
		"dupn" => {
			let idx = popi!();
			push!(env.nth(idx as usize).ok_or(Error::InvalidStackAddress)?.clone())
		},
		"popn" => { let idx = popi!(); env.popn(idx as usize); },
		"a2b" => { let v = pop!(); env.push2(v); },
		"b2a" => { let v = env.pop2().ok_or(Error::PoppedFromEmptyStack)?; env.push(v); },
		"stacklen" => push!(Value::Integer(env.stack().len() as _)),

		"call" => pop!().call(env)?,
		"fetch" => push!({ let s = pops!(); env.lookup(&s).ok_or(Error::UnknownVariable(s))?.clone() }),
		"alloc" => push!(Value::from(Vec::with_capacity(popi!() as usize))),
		"wrapn" => push!({
			let amnt = popi!() as usize;
			let mut v = Vec::with_capacity(amnt);

			for _ in 0..amnt {
				v.insert(0, pop!());
			}

			Value::Block(v.into())
		}),

		"len" => pushi!(match pop!() {
			Value::Array(ary) => ary.borrow().len() as _,
			other => other.to_string().len() as _
		}), 

		"get" => push!({
			let (idx, ary) = (popi!() as usize, pop!());

			match ary {
				Value::Array(ary) => {
					let ary = ary.borrow();
					ary.get(idx)
						.ok_or_else(|| Error::IndexOOB { idx, len: ary.len() })?
						.clone()
				},
				other => {
					let str = other.to_string();
					str.chars()
						.nth(idx)
						.ok_or_else(|| Error::IndexOOB { idx, len: str.len() })
						.map(|x| Value::String(x.to_string().into()))?
				}
			}
		}),

		"set" => {
			let (val, idx, ary) = (pop!(), popi!() as usize, pop!());

			match ary {
				Value::Array(ary) => {
					let mut ary = ary.borrow_mut();
					while ary.len() <= idx {
						ary.push(Value::default());
					}
					ary[idx] = val;
				},
				_other => panic!("todo: set on non-array"),
			}
		},

		"del" => {
			let (idx, ary) = (popi!() as usize, pop!());

			match ary {
				Value::Array(ary) => {
					let mut ary = ary.borrow_mut();
					ary.remove(idx); // todo: check bounds
				},
				_other => panic!("todo: set on non-array"),
			}
		},
		"rev" => {
			match pop!() {
				Value::Array(ary) => push!(
					Value::from({
						let mut x = ary.borrow().iter().cloned().collect::<Vec<_>>();
						x.reverse();
						x
					})),
				_ => panic!("rev on non-array (todo, with number or string?)")
			}
		},
		"split" => push!(pops!()
				.chars()
				.into_iter()
				.map(Value::from)
				.collect::<Vec<_>>()
				.into()),
		"substr" => push!({
			let (len, mut start, string) = (popi!(), popi!(), pops!());

			if start < 0 {
				start += string.len() as i64;

				if start < 0 {
					return Err(Error::IndexOOB{ len: string.len(), idx: start as usize })
				}
			}

			string
				.chars()
				.skip(start as usize)
				.take(len as usize)
				.collect::<String>()
				.into()
		}),
	}
}
