use itertools::Itertools;
use magnus::Ruby;
use marctk::Record;

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

mod ruby_bindings;
mod string_normalize;

pub use ruby_bindings::register_ruby_methods;
pub use string_normalize::trim_punctuation;

use crate::marc::alma::AlmaHoldingId;

pub fn holding_id(
    ruby: &Ruby,
    field_string: String,
    full_record: String,
) -> Result<Option<String>, magnus::Error> {
    let field = field_852(ruby, &field_string)?;
    let record = get_record(ruby, &full_record)?;
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

pub fn is_scsb(ruby: &Ruby, record_string: String) -> Result<bool, magnus::Error> {
    let record = get_record(ruby, &record_string)?;
    Ok(scsb::is_scsb(&record))
}

// Build the permanent location code from 852$b and 852$c
// Do not append the 852c if it is a SCSB - we save the SCSB locations as scsbnypl and scsbcul
pub fn permanent_location_code(
    ruby: &Ruby,
    field_string: String,
) -> Result<Option<String>, magnus::Error> {
    let field = field_852(ruby, &field_string)?;
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
            Some(format!("{b}${c}"))
        }
        _ => field
            .first_subfield("b")
            .map(|subfield| subfield.content().to_string()),
    })
}

fn field_852(ruby: &Ruby, field_string: &String) -> Result<marctk::Field, magnus::Error> {
    let record = get_record(ruby, field_string)?;
    let field_852 = record.get_fields("852").into_iter().next();
    let field_852 = field_852.ok_or_else(|| {
        magnus::Error::new(
            ruby.exception_runtime_error(),
            format!("No 852 field found in record {}", field_string),
        )
    })?;
    Ok(field_852.clone())
}

pub fn current_location_code(
    ruby: &Ruby,
    field_string: String,
) -> Result<Option<String>, magnus::Error> {
    let record = get_record(ruby, &field_string)?;
    let field_876 = record.get_fields("876").into_iter().next();
    Ok(field_876.and_then(
        |field| match (field.first_subfield("y"), field.first_subfield("z")) {
            (Some(y), Some(z)) => Some(format!("{}${}", y.content(), z.content())),
            _ => None,
        },
    ))
}
pub fn build_call_number(
    ruby: &Ruby,
    field_string: String,
) -> Result<Option<String>, magnus::Error> {
    // call_number = [field_852['h'], field_852['i'], field_852['k'], field_852['j']].reject(&:blank?)
    let record = get_record(ruby, &field_string)?;
    let field_852 = record.get_fields("852").into_iter().next();
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

pub fn private_items(
    ruby: &Ruby,
    record_string: String,
    holding_id: String,
) -> Result<bool, magnus::Error> {
    let record = get_record(ruby, &record_string)?;
    let fields_876 = record.get_fields("876");
    let mut items = fields_876.iter().filter(|field| {
        field.first_subfield("0").map(|subfield| subfield.content()) == Some(&holding_id)
    });
    Ok(items.any(|item| {
        item.first_subfield("x")
            .is_none_or(|subfield| subfield.content() == "Private")
    }))
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

fn get_record(ruby: &Ruby, breaker: &str) -> Result<Record, magnus::Error> {
    Record::from_breaker(breaker).map_err(|err| {
        magnus::Error::new(
            ruby.exception_runtime_error(),
            format!("Found error {} while parsing breaker {}", err, breaker),
        )
    })
}
