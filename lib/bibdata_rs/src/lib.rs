use ephemera::ephemera_item;
use magnus::{function, prelude::*, Error, Ruby};

mod config;
mod ephemera;
mod testing_support;
mod theses;

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
        "codes_to_english_names",
        function!(theses::language::codes_to_english_names, 1),
    )?;
    submodule
        .define_singleton_method("call_number", function!(theses::holdings::call_number, 1))?;
    submodule
        .define_singleton_method("online_holding_string", function!(theses::holdings::online_holding_string, 1))?;
    submodule
        .define_singleton_method("physical_holding_string", function!(theses::holdings::physical_holding_string, 1))?;
    Ok(())
}
