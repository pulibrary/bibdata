use ephemera::ephemera_folder_item;
use magnus::{function, prelude::*, Error, Ruby};
use solr::index;
use theses::dataspace::collection;

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
    let submodule_marc = module.define_module("Marc")?;
    let submodule_theses = module.define_module("Theses")?;
    let submodule_ephemera = module.define_module("Ephemera")?;
    submodule_ephemera.define_singleton_method(
        "json_ephemera_document",
        function!(ephemera_folder_item::json_ephemera_document, 1),
    )?;
    submodule_ephemera
        .define_singleton_method("index_string", function!(index::index_string, 3))?;
    submodule_theses.define_singleton_method(
        "all_documents_as_solr",
        function!(collection::collections_as_solr, 3),
    )?;
    submodule_marc.define_singleton_method("genres", function!(marc::genres, 1))?;
    submodule_marc.define_singleton_method("original_languages_of_translation", function!(marc::original_languages_of_translation, 1))?;
    submodule_marc
        .define_singleton_method("strip_non_numeric", function!(marc::strip_non_numeric, 1))?;
    Ok(())
}
