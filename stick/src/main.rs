use stick::{Stream, Environment};

fn main() {
    let val = Stream::new(
        concat!(
            include_str!("prelude.sk"), " ",
            include_str!("file.sk")," ",
            include_str!("foo.sk"), " ",
            include_str!("knight.sk")
        )
    ).value().expect("cant parse value");

    let mut env = Environment::default();

    val.call(&mut env).expect("cant run");
}
