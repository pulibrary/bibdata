use crate::embedding_client::get_embedding;
pub mod embedding_client;
use magnus::{Error, Ruby, function, prelude::*};


#[magnus::init]
fn init(ruby: &Ruby) -> Result<(), Error> {
    let module = ruby.define_module("EmbeddingService")?;
    module.define_singleton_method(
        "get_embedding",
        function!(get_embedding, 1)
    )?;
    Ok(())
}


