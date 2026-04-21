use itertools::Itertools;
use magnus::{RObject, Ruby};
use marctk::{Field, Record};

pub mod alma;
pub mod call_number;
pub mod cjk;
pub mod contributors;
pub mod control_field;
pub mod date;
pub mod extract_values;
pub mod fixed_field;
pub mod genre;
pub mod holdings;
pub mod identifier;
pub mod indigenous_studies;
pub mod language;
pub mod marcxml_compressor;
pub mod note;
pub mod publication;
pub mod record_facet_mapping;
pub mod scsb;
pub mod subject;
pub mod variable_length_field;

mod figgy;
mod non_latin;
mod ruby_bindings;
mod string_normalize;
mod title;

pub use ruby_bindings::register_ruby_methods;
pub use string_normalize::trim_punctuation;

use crate::marc::{
    alma::AlmaHoldingId,
    ruby_bindings::marc_gem::{marctk_data_field_from_ruby_marc, marctk_from_ruby_marc_record},
};

pub fn holding_id(
    ruby: &Ruby,
    field: RObject,
    full_record: RObject,
) -> Result<Option<String>, magnus::Error> {
    let field = marctk_data_field_from_ruby_marc(ruby, &field).ok_or(invalid_field_error(ruby))?;
    let record = marctk_from_ruby_marc_record(ruby, &full_record)?;
    let subfield_code_8 = field.first_subfield("8");
    let subfield_code_0 = field.first_subfield("0");
    match (subfield_code_8, subfield_code_0) {
        (Some(subfield), _) if alma_code_start_22(subfield.content().to_owned()) => {
            Ok(Some(subfield.content().to_owned()))
        }
        (_, Some(subfield)) if scsb::is_scsb(&record) => Ok(Some(subfield.content().to_owned())),
        _ => Ok(None),
    }
}

pub fn alma_code_start_22(code: String) -> bool {
    AlmaHoldingId(&code).is_valid()
}

pub fn is_scsb(ruby: &Ruby, record: magnus::RObject) -> Result<bool, magnus::Error> {
    let record = marctk_from_ruby_marc_record(ruby, &record)?;
    Ok(scsb::is_scsb(&record))
}

pub fn location_codes(ruby: &Ruby, record: RObject) -> Result<Vec<String>, magnus::Error> {
    let record = marctk_from_ruby_marc_record(ruby, &record)?;
    let mut codes = Vec::new();
    for field_852_ref in record.get_fields("852") {
        let field_852 = field_852_ref.clone();

        let holding_id = field_852
            .first_subfield("8")
            .map(|sf| sf.content().to_string());

        let field_876 = holding_id.as_ref().and_then(|id| {
            let all_876 = record.get_fields("876");

            all_876
                .iter()
                .find(|field_876| {
                    field_876
                        .first_subfield("0")
                        .map(|sf| sf.content().to_string())
                        == Some(id.clone())
                })
                .cloned()
        });

        // Calculate permanent and current location codes
        let perm_code = permanent_location_code(&field_852)?;
        let curr_code = field_876.and_then(|field| current_location_code(field));

        let location_code = match (curr_code, perm_code) {
            (Some(curr), Some(perm)) if curr == "RES_SHARE$IN_RS_REQ" => Some(perm),
            (Some(curr), Some(perm)) if curr != perm => Some(curr),
            (Some(curr), _) => Some(curr),
            (None, Some(perm)) => Some(perm),
            _ => None,
        };
        if let Some(c) = location_code {
            codes.push(c);
        }
    }
    Ok(codes)
}

// Build the permanent location code from 852$b and 852$c
// Do not append the 852c if it is a SCSB - we save the SCSB locations as scsbnypl and scsbcul
pub fn ruby_permanent_location_code(
    ruby: &Ruby,
    field: RObject,
) -> Result<Option<String>, magnus::Error> {
    let field = marctk_data_field_from_ruby_marc(ruby, &field).ok_or(invalid_field_error(ruby))?;
    permanent_location_code(&field)
}

fn permanent_location_code(field: &Field) -> Result<Option<String>, magnus::Error> {
    Ok(match field.first_subfield("8") {
        Some(alma_code) if alma_code_start_22(alma_code.content().to_string()) => {
            let b = field
                .first_subfield("b")
                .map(|subfield| subfield.content())
                .unwrap_or_default();
            let c = field
                .first_subfield("c")
                .map(|subfield| subfield.content())
                .unwrap_or_default();
            if c.is_empty() {
                Some(b.to_string())
            } else {
                Some(format!("{b}${c}"))
            }
        }
        None if field.first_subfield("0").is_some() => field
            .first_subfield("b")
            .map(|subfield| subfield.content().to_string()),
        _ => None,
    })
}

pub fn ruby_current_location_code(
    ruby: &Ruby,
    field: RObject,
) -> Result<Option<String>, magnus::Error> {
    let field_876 = marctk_data_field_from_ruby_marc(ruby, &field);
    Ok(field_876.and_then(|field| current_location_code(&field)))
}

fn current_location_code(field: &Field) -> Option<String> {
    match (field.first_subfield("y"), field.first_subfield("z")) {
        (Some(y), Some(z)) => Some(format!("{}${}", y.content(), z.content())),
        _ => None,
    }
}
pub fn build_call_number(ruby: &Ruby, field: RObject) -> Result<Option<String>, magnus::Error> {
    // call_number = [field_852['h'], field_852['i'], field_852['k'], field_852['j']].reject(&:blank?)
    let field_852 = marctk_data_field_from_ruby_marc(ruby, &field);
    let call_number = field_852.map(|field| {
        field
            .subfields()
            .iter()
            .filter(|subfield| ["h", "i", "k", "j"].contains(&subfield.code()))
            .map(|subfield| subfield.content().to_string())
            .filter(|s| !s.is_empty())
            //.collect::<Vec<String>>()
            .join(" ")
    });
    Ok(call_number.filter(|s| !s.is_empty()))
}

pub fn normalize_oclc_number(string: String) -> String {
    identifier::normalize_oclc_number(&string)
}

pub fn is_oclc_number(string: String) -> bool {
    identifier::is_oclc_number(&string)
}

pub fn strip_non_numeric(string: String) -> String {
    string_normalize::strip_non_numeric(&string)
}

pub fn trim_punctuation_owned(string: String) -> String {
    trim_punctuation(&string)
}

fn invalid_field_error(ruby: &Ruby) -> magnus::Error {
    magnus::Error::new(
        ruby.exception_runtime_error(),
        String::from("Invalid field"),
    )
}
