use magnus::exception;
use marctk::Record;

mod string_normalize;

pub mod control_field;
pub mod fixed_field;
pub mod genre;
pub mod language;
pub mod note;
pub mod record_facet_mapping;
pub mod scsb;

pub use string_normalize::trim_punctuation;

pub fn alma_code_start_22(code: String) -> bool {
    code.starts_with("22") && code.ends_with("06421")
}
pub fn genres(record_string: String) -> Result<Vec<String>, magnus::Error> {
    let record = get_record(&record_string)?;
    Ok(genre::genres(&record))
}

pub fn original_languages_of_translation(
    record_string: String,
) -> Result<Vec<String>, magnus::Error> {
    let record = get_record(&record_string)?;
    Ok(language::original_languages_of_translation(&record)
        .iter()
        .map(|language| language.english_name.to_owned())
        .collect())
}

pub fn access_notes(record_string: String) -> Result<Option<Vec<String>>, magnus::Error> {
    let record = get_record(&record_string)?;
    Ok(note::access_notes(&record))
}

pub fn recap_partner_notes(record_string: String) -> Result<Vec<String>, magnus::Error> {
    let record = get_record(&record_string)?;
    Ok(scsb::recap_partner::recap_partner_notes(&record))
}

pub fn is_scsb(record_string: String) -> Result<bool, magnus::Error> {
    let record = get_record(&record_string)?;
    Ok(scsb::is_scsb(&record))
}

pub fn format_facets(record_string: String) -> Result<Vec<String>, magnus::Error> {
    let record = get_record(&record_string)?;
    Ok(record_facet_mapping::format_facets(&record)
        .iter()
        .map(|facet| format!("{facet}"))
        .collect())
}
pub fn non_private_items(record_string: String, holding_id: String) -> Result<bool, magnus::Error> {
    let record = get_record(&record_string)?;
    let fields_876 = record.get_fields("876");
    let mut items = fields_876.iter().filter(|field| {
        field.first_subfield("0").map(|subfield| subfield.content()) == Some(&holding_id)
    });
    Ok(items.any(|item| {
        item.first_subfield("x")
            .map_or(true, |subfield| subfield.content() != "Private")
    }))
}
pub fn strip_non_numeric(string: String) -> String {
    string_normalize::strip_non_numeric(&string)
}

fn get_record(breaker: &str) -> Result<Record, magnus::Error> {
    Record::from_breaker(breaker).map_err(|err| {
        magnus::Error::new(
            exception::runtime_error(),
            format!("Found error {} while parsing breaker {}", err, breaker),
        )
    })
}
