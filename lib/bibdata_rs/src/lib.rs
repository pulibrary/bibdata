use ephemera::ephemera_item;
use magnus::{function, prelude::*, Error, Ruby};
use theses::communities;

mod config;
mod ephemera;
mod theses;

#[cfg(test)]
mod testing_support;

#[magnus::init]
fn init(ruby: &Ruby) -> Result<(), Error> {
    let module = ruby.define_module("BibdataRs")?;
    let submodule = module.define_module("Theses")?;
    let submodule_ephemera = submodule.define_module("Ephemera")?;
    submodule_ephemera.define_singleton_method(
        "json_document",
        function!(ephemera_item::json_ephemera_document, 1),
    )?;
    submodule
        .define_singleton_method("theses_cache_path", function!(theses::theses_cache_path, 0))?;
    submodule.define_singleton_method("rails_env", function!(config::rails_env, 0))?;
    submodule.define_singleton_method(
        "collection_url",
        function!(theses::collection::collection_url, 4),
    )?;
    submodule.define_singleton_method(
        "ruby_json_to_solr_json",
        function!(theses::dataspace::document::ruby_json_to_solr_json, 1),
    )?;
    submodule.define_singleton_method(
        "api_communities_json",
        function!(communities::api_communities_json, 1),
    )?;
    Ok(())
}
