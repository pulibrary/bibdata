use ephemera::ephemera_folder;
use magnus::{function, prelude::*, Error, Ruby};
use solr::index;
use theses::dataspace::collection;
use theses::legacy_dataspace::collection as legacy_collection;

mod ephemera;
pub mod languages;
pub mod marc;
pub mod solr;
pub mod theses;

#[cfg(test)]
mod testing_support;

#[magnus::init]
fn init(ruby: &Ruby) -> Result<(), Error> {
    let module = ruby.define_module("BibdataRs")?;
    let submodule_languages = module.define_module("Languages")?;
    let submodule_theses = module.define_module("Theses")?;
    let submodule_ephemera = module.define_module("Ephemera")?;
    submodule_ephemera.define_singleton_method(
        "json_ephemera_document",
        function!(ephemera_folder::json_ephemera_document, 1),
    )?;
    submodule_ephemera
        .define_singleton_method("index_string", function!(index::index_string, 2))?;
    submodule_theses.define_singleton_method(
        "all_documents_as_solr",
        function!(collection::collections_as_solr, 3),
    )?;
    submodule_theses.define_singleton_method(
        "all_legacy_documents_as_solr",
        function!(legacy_collection::legacy_collections_as_solr, 3),
    )?;
    submodule_languages.define_singleton_method(
        "code_to_name",
        function!(languages::language_code_to_name, 1),
    )?;
    submodule_languages.define_singleton_method(
        "macrolanguage_codes",
        function!(languages::macrolanguage_codes_owned, 1),
    )?;
    submodule_languages.define_singleton_method(
        "valid_language_code?",
        function!(languages::is_valid_language_code, 1),
    )?;
    submodule_languages.define_singleton_method(
        "two_letter_code",
        function!(languages::two_letter_code_owned, 1),
    )?;
    marc::register_ruby_methods(&module)?;
    Ok(())
}
