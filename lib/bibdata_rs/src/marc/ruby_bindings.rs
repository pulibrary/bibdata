use super::*;
use magnus::{function, Module, Object, RModule};

// This module is responsible for the communication between Ruby and Rust code on the topic of MARC
// (specifically the BibdataRs::Marc Ruby module and the crate::marc Rust module)

pub fn register_ruby_methods(parent_module: &RModule) -> Result<(), magnus::Error> {
    let submodule_marc = parent_module.define_module("Marc")?;
    submodule_marc.define_singleton_method("access_notes", function!(access_notes, 1))?;
    submodule_marc
        .define_singleton_method("alma_code_start_22?", function!(alma_code_start_22, 1))?;
    submodule_marc.define_singleton_method("build_call_number", function!(build_call_number, 1))?;
    submodule_marc
        .define_singleton_method("current_location_code", function!(current_location_code, 1))?;
    submodule_marc.define_singleton_method("format_facets", function!(format_facets, 1))?;
    submodule_marc.define_singleton_method("genres", function!(genres, 1))?;
    submodule_marc.define_singleton_method("holding_id", function!(holding_id, 2))?;
    submodule_marc.define_singleton_method(
        "identifiers_of_all_versions",
        function!(identifiers_of_all_versions, 1),
    )?;
    submodule_marc.define_singleton_method("is_oclc_number?", function!(is_oclc_number, 1))?;
    submodule_marc.define_singleton_method("is_scsb?", function!(is_scsb, 1))?;
    submodule_marc
        .define_singleton_method("normalize_oclc_number", function!(normalize_oclc_number, 1))?;
    submodule_marc.define_singleton_method("notes_cjk", function!(notes_cjk, 1))?;
    submodule_marc.define_singleton_method(
        "original_languages_of_translation",
        function!(original_languages_of_translation, 1),
    )?;
    submodule_marc.define_singleton_method(
        "permanent_location_code",
        function!(permanent_location_code, 1),
    )?;
    submodule_marc.define_singleton_method("private_items?", function!(private_items, 2))?;
    submodule_marc.define_singleton_method(
        "publication_statements",
        function!(publication_statements, 1),
    )?;

    submodule_marc
        .define_singleton_method("recap_partner_notes", function!(recap_partner_notes, 1))?;
    submodule_marc.define_singleton_method("strip_non_numeric", function!(strip_non_numeric, 1))?;
    submodule_marc.define_singleton_method("subjects_cjk", function!(subjects_cjk, 1))?;
    submodule_marc
        .define_module_function("trim_punctuation", function!(trim_punctuation_owned, 1))?;
    Ok(())
}
