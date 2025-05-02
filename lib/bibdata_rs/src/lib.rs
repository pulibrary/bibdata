use magnus::{function, prelude::*, Error, Ruby};

fn hello() -> String {
    "toaster".to_owned()
}


#[magnus::init]
fn init(ruby: &Ruby) -> Result<(), Error> {
    let module = ruby.define_module("BibdataRs")?;
    module.define_singleton_method("hello", function!(hello, 0))?;
    Ok(())
}
