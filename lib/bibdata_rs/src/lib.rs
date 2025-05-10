use ephemera::ephemera_item;
use magnus::{function, prelude::*, Error, Ruby};
use theses::{communities, dataspace_document};

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
    submodule.define_singleton_method("json_document", function!(theses::json_document, 1))?;
    submodule_ephemera.define_singleton_method(
        "json_document",
        function!(ephemera_item::json_ephemera_document, 1),
    )?;
    submodule.define_singleton_method("map_program", function!(theses::program::map_program, 1))?;
    submodule.define_singleton_method(
        "map_department",
        function!(theses::department::map_department, 1),
    )?;
    submodule.define_singleton_method(
        "normalize_latex",
        function!(theses::latex::normalize_latex, 1),
    )?;
    submodule
        .define_singleton_method("theses_cache_path", function!(theses::theses_cache_path, 0))?;
    submodule.define_singleton_method("rails_env", function!(config::rails_env, 0))?;
    submodule.define_singleton_method(
        "collection_url",
        function!(theses::collection::collection_url, 4),
    )?;
    submodule.define_singleton_method(
        "has_current_embargo",
        function!(theses::embargo::has_current_embargo, 2),
    )?;
    submodule.define_singleton_method(
        "has_embargo_date",
        function!(theses::embargo::has_embargo_date, 2),
    )?;
    submodule.define_singleton_method(
        "has_parseable_embargo_date",
        function!(theses::embargo::has_parseable_embargo_date, 2),
    )?;
    submodule
        .define_singleton_method("embargo_text", function!(theses::embargo::embargo_text, 3))?;
    submodule.define_singleton_method("looks_like_yes", function!(theses::looks_like_yes, 1))?;
    submodule.define_singleton_method(
        "restrictions_access",
        function!(theses::restrictions::restrictions_access, 2),
    )?;
    submodule.define_singleton_method(
        "ruby_json_to_solr_json",
        function!(theses::dataspace_document::ruby_json_to_solr_json, 1),
    )?;
    submodule.define_singleton_method("api_communities_json", function!(communities::api_communities_json, 1))?;
    Ok(())
}
