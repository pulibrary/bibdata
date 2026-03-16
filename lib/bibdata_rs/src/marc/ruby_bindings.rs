use std::collections::HashMap;

use super::*;
use crate::marc::call_number::{call_number_labels_for_browse, call_number_labels_for_display};
use crate::marc::date::cataloged_date;
use crate::marc::holdings::partner::partner_holdings;
use crate::marc::identifier::identifiers_of_all_versions;
use crate::marc::identifier::map_024_indicators_to_labels;
use crate::marc::note::access_notes;
use crate::marc::{fixed_field::dates::EndDate, scsb::recap_partner::recap_partner_notes};
use crate::solr::AuthorRoles;
use magnus::{Module, Object, RHash, RModule, function};

// This module is responsible for the communication between Ruby and Rust code on the topic of MARC
// (specifically the BibdataRs::Marc Ruby module and the crate::marc Rust module)

pub fn register_ruby_methods(parent_module: &RModule) -> Result<(), magnus::Error> {
    let submodule_marc = parent_module.define_module("Marc")?;
    submodule_marc
        .define_singleton_method("alma_code_start_22?", function!(alma_code_start_22, 1))?;
    submodule_marc.define_singleton_method("build_call_number", function!(build_call_number, 1))?;
    submodule_marc
        .define_singleton_method("current_location_code", function!(current_location_code, 1))?;
    submodule_marc.define_singleton_method(
        "has_main_term_related_to_indigenous_studies",
        function!(has_main_term_related_to_indigenous_studies, 1),
    )?;
    submodule_marc.define_singleton_method(
        "has_subfield_related_to_indigenous_studies",
        function!(has_subfield_related_to_indigenous_studies, 1),
    )?;
    submodule_marc.define_singleton_method("holding_id", function!(holding_id, 2))?;
    submodule_marc.define_module_function("solr_fields", function!(solr_fields, 1))?;
    submodule_marc.define_singleton_method("is_oclc_number?", function!(is_oclc_number, 1))?;
    submodule_marc.define_singleton_method("is_scsb?", function!(is_scsb, 1))?;
    submodule_marc.define_singleton_method("library_label", function!(library_label, 1))?;
    submodule_marc.define_singleton_method("location_label", function!(location_label, 1))?;
    submodule_marc.define_singleton_method(
        "map_024_indicators_to_labels",
        function!(map_024_indicators_to_labels, 1),
    )?;
    submodule_marc
        .define_singleton_method("normalize_oclc_number", function!(normalize_oclc_number, 1))?;
    submodule_marc.define_singleton_method(
        "partner_holdings_1display",
        function!(partner_holdings_1display, 1),
    )?;
    submodule_marc.define_singleton_method(
        "permanent_location_code",
        function!(permanent_location_code, 1),
    )?;
    submodule_marc.define_singleton_method("private_items?", function!(private_items, 2))?;
    submodule_marc.define_singleton_method("strip_non_numeric", function!(strip_non_numeric, 1))?;
    submodule_marc
        .define_module_function("trim_punctuation", function!(trim_punctuation_owned, 1))?;
    Ok(())
}

fn solr_fields(ruby: &Ruby, record_string: String) -> Result<RHash, magnus::Error> {
    let record = get_record(ruby, &record_string)?;

    let author_roles_1display =
        serde_json::to_string(&AuthorRoles::from(&record)).map_err(|err| {
            magnus::Error::new(
                ruby.exception_runtime_error(),
                format!("Found error {} while serializing author roles", err),
            )
        })?;
    let format: Vec<_> = record_facet_mapping::format_facets(&record)
        .iter()
        .map(|facet| format!("{facet}"))
        .collect();
    let icpsr_subject_unstem_search = subject::icpsr_subjects(&record);
    let original_language_of_translation_facet: Vec<_> =
        language::original_languages_of_translation(&record)
            .iter()
            .map(|language| language.english_name.to_owned())
            .collect();
    let pub_date_end_sort = EndDate::try_from(&record)
        .ok()
        .and_then(|date| date.maybe_to_string());

    let hash = ruby.hash_new_capa(17);
    hash.aset("access_restrictions_note_display", access_notes(&record))?;
    hash.aset("author_roles_1display", author_roles_1display)?;
    hash.aset(
        "call_number_browse_s",
        call_number_labels_for_browse(&record),
    )?;
    hash.aset(
        "call_number_display",
        call_number_labels_for_display(&record),
    )?;
    hash.aset("cataloged_date_tdt", cataloged_date(&record))?;
    hash.aset("cjk_notes", ruby.ary_from_iter(cjk::notes_cjk(&record)))?;
    hash.aset(
        "cjk_subject",
        ruby.ary_from_iter(cjk::subjects_cjk(&record)),
    )?;
    hash.aset("format", format)?;
    hash.aset("genre_facet", genre::genres(&record))?;
    hash.aset("icpsr_subject_unstem_search", icpsr_subject_unstem_search)?;
    hash.aset("other_version_s", identifiers_of_all_versions(&record))?;
    hash.aset(
        "original_language_of_translation_facet",
        original_language_of_translation_facet,
    )?;
    hash.aset(
        "pub_citation_display",
        ruby.ary_from_iter(publication::pub_citation_display(&record)),
    )?;
    hash.aset(
        "pub_created_display",
        ruby.ary_from_iter(publication::pub_created_display(&record)),
    )?;
    hash.aset("pub_date_end_sort", pub_date_end_sort)?;
    hash.aset("recap_notes_display", recap_partner_notes(&record))?;
    hash.aset(
        "siku_subject_display",
        ruby.ary_from_iter(subject::siku_subjects_display(&record)),
    )?;

    Ok(hash)
}

fn has_subfield_related_to_indigenous_studies(term: String) -> Result<bool, magnus::Error> {
    Ok(indigenous_studies::has_subfield_related_to_indigenous_studies(&term))
}

fn has_main_term_related_to_indigenous_studies(term: String) -> Result<bool, magnus::Error> {
    Ok(indigenous_studies::has_main_term_related_to_indigenous_studies(&term))
}

fn library_label(code: String) -> Option<String> {
    holdings::holding_location::library_label(&code).map(|label| label.to_owned())
}

fn location_label(code: String) -> Option<String> {
    holdings::holding_location::location_label(&code).map(|label| label.to_owned())
}

fn partner_holdings_1display(
    ruby: &Ruby,
    record_string: String,
) -> Result<Option<String>, magnus::Error> {
    let record = get_record(ruby, &record_string)?;
    let holdings: Vec<holdings::partner::PartnerHolding<'_>> = partner_holdings(&record).collect();
    if holdings.is_empty() {
        Ok(None)
    } else {
        let mut hash = HashMap::new();
        for holding in holdings {
            hash.insert(holding.holding_id, holding);
        }
        Ok(Some(serde_json::to_string(&hash).map_err(|err| {
            magnus::Error::new(
                ruby.exception_runtime_error(),
                format!("Found error {} while serializing partner holdings", err),
            )
        })?))
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use magnus::Ruby;
    use rb_sys_test_helpers::ruby_test;

    #[ruby_test]
    fn it_binds_solr_fields_method() {
        let ruby = unsafe { Ruby::get_unchecked() };
        let module = ruby.define_module("MyNiceModule").unwrap();
        register_ruby_methods(&module).unwrap();
        let method_exists: bool = ruby
            .eval("MyNiceModule::Marc.respond_to? :solr_fields")
            .unwrap();
        assert!(method_exists);
    }
}
