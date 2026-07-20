use std::collections::HashMap;
use std::fs;

pub mod marc_gem;

use super::*;
use crate::marc::call_number::{call_number_labels_for_browse, call_number_labels_for_display};
use crate::marc::control_field::control_number::ControlNumber;
use crate::marc::control_field::partner_id::other_id;
use crate::marc::control_field::system_control_number::standard_numbers;
use crate::marc::date::cataloged_date;
use crate::marc::figgy::figgy_1display;
use crate::marc::fixed_field::dates::BeginDate;
use crate::marc::holdings::partner::partner_holdings;
use crate::marc::identifier::identifiers_of_all_versions;
use crate::marc::identifier::map_024_indicators_to_labels;
use crate::marc::marcxml_compressor::marcxml_compressed;
use crate::marc::note::access_notes;
use crate::marc::note::action_note::action_notes;
use crate::marc::ruby_bindings::marc_gem::marctk_from_ruby_marc_record;
use crate::marc::title;
use crate::marc::variable_length_field::extract_marc;
use crate::marc::{fixed_field::dates::EndDate, scsb::recap_partner::recap_partner_notes};
use crate::paths::APPLICATION_ROOT;
use crate::solr::AuthorRoles;
use figgy_marc::only_open;
use magnus::{Module, Object, RArray, RHash, RModule, function};

// This module is responsible for the communication between Ruby and Rust code on the topic of MARC
// (specifically the BibdataRs::Marc Ruby module and the crate::marc Rust module)

pub fn register_ruby_methods(parent_module: &RModule) -> Result<(), magnus::Error> {
    let submodule_marc = parent_module.define_module("Marc")?;
    submodule_marc
        .define_singleton_method("alma_code_start_22?", function!(alma_code_start_22, 1))?;
    submodule_marc.define_singleton_method("build_call_number", function!(build_call_number, 1))?;
    submodule_marc.define_singleton_method(
        "current_location_code",
        function!(ruby_current_location_code, 1),
    )?;
    submodule_marc.define_singleton_method(
        "indicates_indigenous_studies?",
        function!(indicates_indigenous_studies, 1),
    )?;
    submodule_marc.define_singleton_method("holding_id", function!(holding_id, 2))?;
    submodule_marc.define_module_function("solr_fields", function!(solr_fields, 1))?;
    submodule_marc.define_singleton_method("is_scsb?", function!(is_scsb, 1))?;
    submodule_marc.define_module_function("location_codes", function!(ruby_location_codes, 1))?;
    submodule_marc.define_singleton_method("library_label", function!(library_label, 1))?;
    submodule_marc.define_singleton_method("location_label", function!(location_label, 1))?;
    submodule_marc.define_singleton_method("manifest_url", function!(manifest_url, 1))?;
    submodule_marc.define_singleton_method(
        "mapped_codes_location_label",
        function!(mapped_codes_location_label, 1),
    )?;
    submodule_marc.define_singleton_method(
        "map_024_indicators_to_labels",
        function!(map_024_indicators_to_labels, 1),
    )?;
    submodule_marc.define_singleton_method("mms_id", function!(mms_id, 1))?;
    submodule_marc.define_singleton_method(
        "partner_holdings_1display",
        function!(partner_holdings_1display, 1),
    )?;
    submodule_marc.define_singleton_method(
        "permanent_location_code",
        function!(ruby_permanent_location_code, 1),
    )?;
    submodule_marc.define_singleton_method(
        "index_test_figgy_data_into_redis",
        function!(index_test_figgy_data_into_redis, 0),
    )?;
    submodule_marc.define_singleton_method("strip_non_numeric", function!(strip_non_numeric, 1))?;
    submodule_marc
        .define_module_function("trim_punctuation", function!(trim_punctuation_owned, 1))?;
    Ok(())
}

/// A Ruby hash of solr field names and values
fn solr_fields(ruby: &Ruby, record: magnus::RObject) -> Result<RHash, magnus::Error> {
    let record = marctk_from_ruby_marc_record(ruby, &record)?;

    let action_notes_1display = ruby.ary_new();
    let action_notes = action_notes(&record).collect::<Vec<_>>();

    if !action_notes.is_empty()
        && let Ok(notes) = serde_json::to_string(&action_notes)
    {
        action_notes_1display.push(notes)?;
    }

    let author_roles_1display = AuthorRoles::from(&record).to_string();
    let format: Vec<_> = record_facet_mapping::format_facets(&record)
        .iter()
        .map(|facet| format!("{facet}"))
        .collect();
    let icpsr_subject_unstem_search = subject::icpsr_subjects(&record);
    let title_t = title::latin_script_title(&record);

    let original_language_of_translation_facet: Vec<_> =
        language::original_languages_of_translation(&record)
            .iter()
            .map(|language| language.english_name.to_owned())
            .collect();
    let pub_date_start_sort = BeginDate::try_from(&record)
        .ok()
        .and_then(|date| date.maybe_to_string());
    let pub_date_end_sort = EndDate::try_from(&record)
        .ok()
        .and_then(|date| date.maybe_to_string());

    let hash = ruby.hash_new_capa(117);
    hash.aset("aat_s", ruby.ary_from_iter(genre::aat_s(&record)))?;
    hash.aset("action_notes_1display", action_notes_1display)?;
    hash.aset("access_restrictions_note_display", access_notes(&record))?;
    hash.aset("alt_title_246_display", extract_marc!("246abfnp")(&record))?;
    hash.aset(
        "author_display",
        ruby.ary_from_iter(
            extract_marc!("100aqbcdk", "110abcdfgkln", "111abcdfgklnpq")(&record)
                .iter()
                .map(|author| trim_punctuation(author)),
        ),
    )?;
    hash.aset("arrangement_display", extract_marc!("351abc")(&record))?;
    hash.aset("author_roles_1display", author_roles_1display)?;
    hash.aset("bib_ref_notes_display", extract_marc!("504ab")(&record))?;
    hash.aset("binding_note_display", extract_marc!("563au3")(&record))?;
    hash.aset(
        "biographical_historical_note_display",
        extract_marc!("545ab")(&record),
    )?;
    hash.aset(
        "call_number_browse_s",
        call_number_labels_for_browse(&record),
    )?;
    hash.aset(
        "call_number_display",
        call_number_labels_for_display(&record),
    )?;
    hash.aset(
        "case_file_notes_display",
        extract_marc!("5653abcde")(&record),
    )?;
    hash.aset("cataloged_tdt", cataloged_date(&record))?;
    hash.aset("cite_as_display", extract_marc!("52423a")(&record))?;
    hash.aset("cjk_author", ruby.ary_from_iter(cjk::cjk_authors(&record)))?;
    hash.aset("cjk_all", ruby.ary_from_iter(cjk::cjk_all(&record)))?;
    hash.aset("cjk_notes", ruby.ary_from_iter(cjk::notes_cjk(&record)))?;
    hash.aset(
        "cjk_series_title",
        ruby.ary_from_iter(cjk::cjk_series_titles(&record)),
    )?;
    hash.aset(
        "cjk_subject",
        ruby.ary_from_iter(cjk::subjects_cjk(&record)),
    )?;
    hash.aset("cjk_title", ruby.ary_from_iter(cjk::cjk_titles(&record)))?;
    hash.aset("coden_display", extract_marc!("030a")(&record))?;
    hash.aset("compiled_created_display", extract_marc!("245fg")(&record))?;
    hash.aset(
        "contains_title_index",
        ruby.ary_from_iter(title::contains_titles_index(&record)),
    )?;
    hash.aset("content_title_index", extract_marc!("505t")(&record))?;
    hash.aset(
        "copy_version_notes_display",
        extract_marc!("5623abcde")(&record),
    )?;
    hash.aset("credits_notes_display", extract_marc!("508a")(&record))?;
    hash.aset(
        "data_quality_notes_display",
        extract_marc!("514abcdefghijkm")(&record),
    )?;
    hash.aset(
        "date_place_event_notes_display",
        extract_marc!("5183adop")(&record),
    )?;
    hash.aset(
        "description_display",
        extract_marc!(
            "254a",
            "255abcdefg",
            "3422abcdefghijklmnopqrstuv",
            "343abcdefghi",
            "352abcdegi",
            "355abcdefghj",
            "507ab",
            "256a",
            "516a",
            "753abc",
            "755axyz",
            "3003abcefg",
            "362az"
        )(&record),
    )?;
    hash.aset(
        "description_t",
        extract_marc!(
            "254a",
            "255abcdefg",
            "3422abcdefghijklmnopqrstuv",
            "343abcdefghi",
            "352abcdegi",
            "355abcdefghj",
            "507ab",
            "256a",
            "516a",
            "753abc",
            "755axyz",
            "3003abcefg",
            "515a",
            "362az"
        )(&record),
    )?;
    hash.aset(
        "dissertation_notes_display",
        extract_marc!("502abcdgo")(&record),
    )?;
    hash.aset("edition_display", extract_marc!("250ab")(&record))?;
    hash.aset("exhibitions_note_display", extract_marc!("5853a")(&record))?;
    hash.aset(
        "fast_subject_display",
        ruby.ary_from_iter(subject::fast_subjects(&record)),
    )?;
    hash.aset("figgy_1display", figgy_1display(&record))?;
    hash.aset("format", format)?;
    hash.aset("former_frequency_display", extract_marc!("321ab")(&record))?;
    hash.aset(
        "former_title_complex_notes_display",
        extract_marc!("547a")(&record),
    )?;
    hash.aset("frequency_display", extract_marc!("310ab")(&record))?;
    hash.aset(
        "funding_info_notes_display",
        extract_marc!("536abcdefgh")(&record),
    )?;
    hash.aset("genre_facet", genre::genres(&record))?;
    hash.aset("geo_cov_notes_display", extract_marc!("522a")(&record))?;
    hash.aset(
        "homoit_genre_s",
        ruby.ary_from_iter(genre::homoit_genre_s(&record)),
    )?;
    hash.aset("icpsr_subject_unstem_search", icpsr_subject_unstem_search)?;
    hash.aset(
        "id",
        record
            .get_control_fields("001")
            .first()
            .map(|field| field.content().to_owned()),
    )?;
    hash.aset(
        "info_document_notes_display",
        extract_marc!("556a")(&record),
    )?;
    hash.aset(
        "isbn_s",
        ruby.ary_from_iter(standard_number::normalized_isbns(&record)),
    )?;
    hash.aset(
        "issn_s",
        ruby.ary_from_iter(standard_number::normalized_issns(&record)),
    )?;
    hash.aset(
        "lccn_s",
        ruby.ary_from_iter(standard_number::normalized_lccns(&record)),
    )?;
    hash.aset("issn_display", extract_marc!("022a")(&record))?;
    hash.aset("issuing_body_notes_display", extract_marc!("550a")(&record))?;
    hash.aset("language_display", extract_marc!("5463a")(&record))?;
    hash.aset(
        "linked_series_index",
        extract_marc!("760acgst", "762acgst")(&record),
    )?;
    hash.aset(
        "linked_series_title_index",
        extract_marc!(
            "765k", "767k", "770k", "772k", "773k", "774k", "775k", "776k", "777k", "780k", "785k",
            "786k", "787k"
        )(&record),
    )?;
    hash.aset(
        "linked_title_index",
        extract_marc!(
            "765st", "767st", "770st", "772st", "773st", "774st", "775st", "776st", "777st",
            "780st", "785st", "786st", "787st"
        )(&record),
    )?;
    hash.aset("lccn_display", extract_marc!("010a")(&record))?;
    hash.aset("lcgft_s", ruby.ary_from_iter(genre::lcgft_s(&record)))?;
    hash.aset("linking_notes_display", extract_marc!("580a")(&record))?;
    hash.aset("location", holdings::library::location_facet(&record))?;
    hash.aset(
        "location_originals_notes_display",
        extract_marc!("5353abcdg")(&record),
    )?;
    hash.aset(
        "location_other_arch_notes_display",
        extract_marc!("5443abcden")(&record),
    )?;
    hash.aset("marcxml", marcxml_compressed(&record))?;
    hash.aset("methodology_notes_display", extract_marc!("567a")(&record))?;
    hash.aset(
        "non_latin_non_cjk_all_index",
        ruby.ary_from_iter(non_latin::non_latin_non_cjk_all(&record)),
    )?;
    hash.aset(
        "non_latin_non_cjk_author_index",
        ruby.ary_from_iter(non_latin::non_latin_non_cjk_authors(&record)),
    )?;
    hash.aset(
        "non_latin_non_cjk_series_title_index",
        ruby.ary_from_iter(non_latin::non_latin_non_cjk_series_titles(&record)),
    )?;
    hash.aset(
        "non_latin_non_cjk_title_index",
        ruby.ary_from_iter(non_latin::non_latin_non_cjk_titles(&record)),
    )?;
    hash.aset("notes_display", extract_marc!("5003a", "590a")(&record))?;
    hash.aset(
        "numbering_pec_notes_display",
        extract_marc!("515a")(&record),
    )?;
    hash.aset(
        "numeric_id_b",
        matches!(ControlNumber::from(&record), ControlNumber::Alma(_)),
    )?;
    hash.aset(
        "original_language_display",
        non_latin::unmatched_non_latin_strings(&record),
    )?;
    hash.aset(
        "original_version_notes_display",
        extract_marc!("534abcefklmnpt3")(&record),
    )?;
    hash.aset("other_editions_s", extract_marc!("775w")(&record))?;
    hash.aset("other_format_display", extract_marc!("5303abcd")(&record))?;
    hash.aset(
        "other_title_index",
        extract_marc!(
            "246abfnp",
            "210ab",
            "211a",
            "212a",
            "214a",
            "222ab",
            "242abchnp",
            "243adfklmnoprs",
            "247abfhnp",
            "730aplskfmnor",
            "740ahnp"
        )(&record),
    )?;
    hash.aset(
        "original_version_series_index",
        extract_marc!("534f")(&record),
    )?;
    hash.aset("other_id_s", other_id(&record))?;
    hash.aset(
        "oclc_s",
        ruby.ary_from_iter(identifier::oclc_numbers_numeric(&record)),
    )?;
    hash.aset("other_version_s", identifiers_of_all_versions(&record))?;
    hash.aset(
        "original_language_of_translation_facet",
        original_language_of_translation_facet,
    )?;
    hash.aset(
        "participant_performer_display",
        extract_marc!("511a")(&record),
    )?;
    hash.aset("place_name_display", extract_marc!("752abcd")(&record))?;
    hash.aset(
        "pub_citation_display",
        ruby.ary_from_iter(publication::pub_citation_display(&record)),
    )?;
    hash.aset(
        "pub_created_s",
        extract_marc!("260abcefg", "264abcefg3")(&record),
    )?;
    hash.aset(
        "pub_created_display",
        ruby.ary_from_iter(publication::pub_created_display(&record)),
    )?;
    hash.aset(
        "publications_about_display",
        extract_marc!("581az36")(&record),
    )?;
    hash.aset("publisher_no_display", extract_marc!("028a")(&record))?;
    hash.aset("projection_display", extract_marc!("255b", "342a")(&record))?;
    hash.aset("pub_date_display", pub_date_start_sort.clone())?;
    hash.aset("pub_date_start_sort", pub_date_start_sort)?;
    hash.aset("pub_date_end_sort", pub_date_end_sort)?;
    hash.aset("rbgenr_s", ruby.ary_from_iter(genre::rbgenr_s(&record)))?;
    hash.aset("recap_notes_display", recap_partner_notes(&record))?;
    hash.aset(
        "related_record_info_display",
        extract_marc!("776i")(&record),
    )?;
    hash.aset(
        "reproduction_notes_display",
        extract_marc!("5333abcdefmn")(&record),
    )?;
    hash.aset(
        "restrictions_note_display",
        extract_marc!("5063abcde")(&record),
    )?;
    hash.aset(
        "rights_reproductions_note_display",
        extract_marc!("5403abcd")(&record),
    )?;
    hash.aset("scale_display", extract_marc!("255a")(&record))?;
    hash.aset("script_display", extract_marc!("546b")(&record))?;
    hash.aset("series_statement_index", extract_marc!("490avx")(&record))?;
    hash.aset(
        "siku_subject_display",
        ruby.ary_from_iter(subject::siku_subjects_display(&record)),
    )?;
    hash.aset("standard_no_024_index", extract_marc!("024a")(&record))?;
    hash.aset(
        "standard_no_index",
        standard_numbers_for_ruby(ruby, &record),
    )?;
    hash.aset("sudoc_no_display", extract_marc!("086a")(&record))?;
    hash.aset("supplement_notes_display", extract_marc!("525a")(&record))?;
    hash.aset(
        "system_details_notes_display",
        extract_marc!("5383ai")(&record),
    )?;
    hash.aset("target_aud_notes_display", extract_marc!("5213ab")(&record))?;
    hash.aset(
        "title_a_index",
        ruby.ary_from_iter(
            extract_marc!("245a")(&record)
                .iter()
                .map(|author| trim_punctuation(author)),
        ),
    )?;
    hash.aset(
        "title_display",
        extract_marc!(latin "245abcfghknps")(&record),
    )?;
    hash.aset(
        "title_no_h_index",
        ruby.ary_from_iter(title::title_no_h_index(&record)),
    )?;
    hash.aset("title_sort", title::title_sort(&record))?;
    hash.aset("title_vern_sort", title::non_latin_title_sort(&record))?;
    hash.aset("title_t", title_t)?;
    hash.aset("type_period_notes_display", extract_marc!("513ab")(&record))?;
    hash.aset(
        "uniform_130_vern",
        ruby.ary_from_iter(title::uniform_130_non_latin(&record)),
    )?;
    hash.aset("with_notes_display", extract_marc!("501a")(&record))?;

    Ok(hash)
}

fn indicates_indigenous_studies(terms: magnus::RArray) -> Result<bool, magnus::Error> {
    Ok(indigenous_studies::indicates_indigenous_studies(
        &terms.to_vec::<String>()?,
    ))
}

fn index_test_figgy_data_into_redis() {
    let json_fixture_path = APPLICATION_ROOT.join("spec/fixtures/files/figgy/figgy_report.json");
    let json = fs::read_to_string(&json_fixture_path).unwrap_or_else(|_| panic!("Could not find the figgy_report in the fixtures directory, please check the path ({}), which is referenced in file {}", json_fixture_path.to_str().unwrap(), file!()));
    let test_data: figgy_marc::FiggyMmsIdCache = serde_json::from_str(&json).unwrap();
    figgy_marc::redis_cache::write(&only_open(&test_data));
}

fn library_label(code: String) -> Option<String> {
    holdings::holding_location::library_label(&code).map(|label| label.to_owned())
}

fn location_label(code: String) -> Option<String> {
    holdings::holding_location::location_label(&code).map(|label| label.to_owned())
}

fn mapped_codes_location_label(code: String) -> HashMap<String, String> {
    holdings::holding_location::mapped_codes_location_label(&code)
        .into_iter()
        .map(|(code, label)| (code.to_owned(), label.to_owned()))
        .collect()
}

fn partner_holdings_1display(
    ruby: &Ruby,
    record: magnus::RObject,
) -> Result<Option<String>, magnus::Error> {
    let record = marctk_from_ruby_marc_record(ruby, &record)?;
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

fn standard_numbers_for_ruby(ruby: &Ruby, record: &Record) -> RArray {
    ruby.ary_from_iter(
        standard_numbers(record)
            .map(|number| ruby.enc_str_new(number.as_bytes(), ruby.utf8_encoding())),
    )
}

fn ruby_location_codes(ruby: &Ruby, record: RObject) -> Result<Vec<String>, magnus::Error> {
    let record = marctk_from_ruby_marc_record(ruby, &record)?;
    let codes = holdings::holding_location::location_codes(&record);
    Ok(codes)
}

// Build the permanent location code from 852$b and 852$c
// Do not append the 852c if it is a SCSB - we save the SCSB locations as scsbnypl and scsbcul
fn ruby_permanent_location_code(
    ruby: &Ruby,
    field: RObject,
) -> Result<Option<String>, magnus::Error> {
    let field = marctk_data_field_from_ruby_marc(ruby, &field).ok_or(invalid_field_error(ruby))?;
    Ok(holdings::holding_location::alma_permanent_location_code(
        &field,
    ))
}

fn ruby_current_location_code(
    ruby: &Ruby,
    field: RObject,
) -> Result<Option<String>, magnus::Error> {
    let field_876 = marctk_data_field_from_ruby_marc(ruby, &field);
    Ok(field_876.and_then(|field| holdings::holding_location::current_location_code(&field)))
}

fn manifest_url(
    ruby: &Ruby,
    ark: magnus::RString,
) -> Result<Option<magnus::RString>, magnus::Error> {
    Ok(figgy::manifest_url(&ark.to_string()?, None).map(|manifest_url| ruby.str_new(manifest_url)))
}

fn mms_id(ruby: &Ruby, ark: magnus::RString) -> Result<Option<magnus::RString>, magnus::Error> {
    Ok(figgy::mms_id(&ark.to_string()?, None).map(|mms_id| ruby.str_new(mms_id)))
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

    #[ruby_test]
    fn it_includes_rbgenr_s_in_solr_fields() {
        let ruby = unsafe { Ruby::get_unchecked() };
        let ruby_record: magnus::RObject = ruby.eval(r"require 'marc';record = MARC::Record.new;record.append(MARC::DataField.new( '655', '', '7', ['a', 'Dictionaries'], ['x', 'French'], ['y', '18th century.'], ['2', 'rbgenr']));record").unwrap();
        let hash = solr_fields(&ruby, ruby_record).unwrap();

        let rbgenr_s_value = hash.aref::<&str, Vec<String>>("rbgenr_s").unwrap();
        assert_eq!(
            rbgenr_s_value,
            vec![String::from("Dictionaries—French—18th century")]
        );
    }

    #[ruby_test]
    fn it_includes_author_roles_in_solr_fields() {
        let ruby = unsafe { Ruby::get_unchecked() };
        let ruby_record: magnus::RObject = ruby.eval(r"require 'marc';record = MARC::Record.new;record.append(MARC::DataField.new( '700', '1', '', ['a', 'Sethi, Bishnupada, '], ['d', '1967-']));record").unwrap();
        let hash = solr_fields(&ruby, ruby_record).unwrap();

        let author_roles_value = hash.aref::<&str, String>("author_roles_1display").unwrap();
        assert_eq!(
            author_roles_value,
            String::from(
                r#"{"secondary_authors":["Sethi, Bishnupada"],"translators":[],"editors":[],"compilers":[]}"#
            )
        );
    }

    #[ruby_test]
    fn it_includes_other_id_s_in_solr_fields() {
        let ruby = unsafe { Ruby::get_unchecked() };
        let ruby_record: magnus::RObject = ruby.eval(r"require 'marc';record = MARC::Record.new;record.append(MARC::ControlField.new('009', '.b118131060'));record").unwrap();
        let hash = solr_fields(&ruby, ruby_record).unwrap();

        let other_id_value: Option<String> = hash.aref("other_id_s").unwrap();
        assert_eq!(other_id_value, Some(".b118131060".to_owned()));
    }

    #[ruby_test]
    fn it_includes_oclc_s_in_solr_fields() {
        let ruby = unsafe { Ruby::get_unchecked() };
        let ruby_record: magnus::RObject = ruby.eval(r"require 'marc';record = MARC::Record.new;record.append(MARC::DataField.new('035', '', '', ['a', '(OCoLC)ocn989083934 ']));record").unwrap();
        let hash = solr_fields(&ruby, ruby_record).unwrap();

        let oclc_value = hash.aref::<&str, Vec<String>>("oclc_s").unwrap();
        assert_eq!(oclc_value, vec![String::from("989083934")]);
    }

    #[ruby_test]
    fn it_includes_scale_display_in_solr_fields() {
        let ruby = unsafe { Ruby::get_unchecked() };
        let ruby_record: magnus::RObject = ruby.eval(r#"require 'marc';record = MARC::Record.new;record.append(MARC::DataField.new('255', '', '', ['a', 'Scale [1:6,336,000]. 1" = 100 miles. Vertical scale [1:192,000]. 1/16" = approx. 1000\'.']));record"#).unwrap();
        let hash = solr_fields(&ruby, ruby_record).unwrap();

        let scale_display_value = hash.aref::<&str, Vec<String>>("scale_display").unwrap();
        assert_eq!(
            scale_display_value,
            vec![String::from(
                r#"Scale [1:6,336,000]. 1" = 100 miles. Vertical scale [1:192,000]. 1/16" = approx. 1000'."#
            )]
        );
    }
}
