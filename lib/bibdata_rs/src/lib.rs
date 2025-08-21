use ephemera::ephemera_folder;
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
        function!(ephemera_folder::json_ephemera_document, 1),
    )?;
    submodule_ephemera
        .define_singleton_method("index_string", function!(index::index_string, 2))?;
    submodule_theses.define_singleton_method(
        "all_documents_as_solr",
        function!(collection::collections_as_solr, 3),
    )?;
    submodule_marc.define_singleton_method("access_notes", function!(marc::access_notes, 1))?;
    submodule_marc.define_singleton_method("genres", function!(marc::genres, 1))?;
    submodule_marc.define_singleton_method(
        "original_languages_of_translation",
        function!(marc::original_languages_of_translation, 1),
    )?;
    submodule_marc
        .define_singleton_method("strip_non_numeric", function!(marc::strip_non_numeric, 1))?;

    submodule_marc.define_singleton_method("format_facets", function!(marc::format_facets, 1))?;
    submodule_marc.define_singleton_method(
        "alma_code_start_22?",
        function!(marc::alma_code_start_22, 1),
    )?;
    submodule_marc.define_singleton_method("is_scsb?", function!(marc::is_scsb, 1))?;
    submodule_marc.define_singleton_method(
        "recap_partner_notes",
        function!(marc::recap_partner_notes, 1),
    )?;
    submodule_marc.define_singleton_method("private_items?", function!(marc::private_items, 2))?;
    submodule_marc.define_singleton_method(
        "normalize_oclc_number",
        function!(marc::normalize_oclc_number, 1),
    )?;
    submodule_marc.define_singleton_method(
        "identifiers_of_all_versions",
        function!(marc::identifiers_of_all_versions, 1),
    )?;
    submodule_marc
        .define_singleton_method("is_oclc_number?", function!(marc::is_oclc_number, 1))?;
    submodule_marc.define_singleton_method(
        "current_location_code",
        function!(marc::current_location_code, 1),
    )?;
    submodule_marc.define_singleton_method(
        "permanent_location_code",
        function!(marc::permanent_location_code, 1),
    )?;
    submodule_marc.define_singleton_method(
        "publication_statements",
        function!(marc::publication_statements, 1),
    )?;
    submodule_marc
        .define_singleton_method("build_call_number", function!(marc::build_call_number, 1))?;
    Ok(())
}
