#[derive(Debug)]
pub enum Error {
	UnknownVariable(String),
	CannotCall(&'static str),
	PoppedFromEmptyStack,
	InvalidStackAddress,
	IndexOOB { len: usize, idx: usize },
	Custom(String),
	Return(usize)
}
