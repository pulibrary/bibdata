use itertools::Itertools;
use magnus::exception;
use marctk::Record;

mod string_normalize;

pub mod control_field;
pub mod fixed_field;
pub mod genre;
pub mod identifier;
pub mod language;
pub mod note;
pub mod publication;
pub mod record_facet_mapping;
pub mod scsb;
pub mod variable_length_field;

pub use string_normalize::trim_punctuation;
use unicode_blocks::is_cjk;

pub fn holding_id(
    field_string: String,
    full_record: String,
) -> Result<Option<String>, magnus::Error> {
    let field = field_852(&field_string)?;
    let record = get_record(&full_record)?;
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

// Build the permanent location code from 852$b and 852$c
// Do not append the 852c if it is a SCSB - we save the SCSB locations as scsbnypl and scsbcul
pub fn permanent_location_code(field_string: String) -> Result<Option<String>, magnus::Error> {
    let field = field_852(&field_string)?;
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

fn field_852(field_string: &String) -> Result<marctk::Field, magnus::Error> {
    let record = get_record(field_string)?;
    let field_852 = record.get_fields("852").into_iter().next();
    let field_852 = field_852.ok_or_else(|| {
        magnus::Error::new(
            exception::runtime_error(),
            format!("No 852 field found in record {}", field_string),
        )
    })?;
    Ok(field_852.clone())
}

pub fn current_location_code(field_string: String) -> Result<Option<String>, magnus::Error> {
    let record = get_record(&field_string)?;
    let field_876 = record.get_fields("876").into_iter().next();
    Ok(field_876.and_then(
        |field| match (field.first_subfield("y"), field.first_subfield("z")) {
            (Some(y), Some(z)) => Some(format!("{}${}", y.content(), z.content())),
            _ => None,
        },
    ))
}
pub fn build_call_number(field_string: String) -> Result<Option<String>, magnus::Error> {
    // call_number = [field_852['h'], field_852['i'], field_852['k'], field_852['j']].reject(&:blank?)
    let record = get_record(&field_string)?;
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

pub fn format_facets(record_string: String) -> Result<Vec<String>, magnus::Error> {
    let record = get_record(&record_string)?;
    Ok(record_facet_mapping::format_facets(&record)
        .iter()
        .map(|facet| format!("{facet}"))
        .collect())
}
pub fn private_items(record_string: String, holding_id: String) -> Result<bool, magnus::Error> {
    let record = get_record(&record_string)?;
    let fields_876 = record.get_fields("876");
    let mut items = fields_876.iter().filter(|field| {
        field.first_subfield("0").map(|subfield| subfield.content()) == Some(&holding_id)
    });
    Ok(items.any(|item| {
        item.first_subfield("x")
            .map_or(true, |subfield| subfield.content() == "Private")
    }))
}

pub fn subjects_cjk(record_string: String) -> Result<Vec<String>, magnus::Error> {
    let record = get_record(&record_string)?;
    Ok(extract_parallel_values(
        &record,
        "600",
        "*",
        "0",
        &[
            "a", "b", "c", "d", "f", "k", "l", "m", "n", "o", "p", "q", "r", "t", "v", "x", "y",
            "z",
        ],
    )
    .chain(extract_parallel_values(
        &record,
        "610",
        "*",
        "0",
        &[
            "a", "b", "f", "k", "l", "m", "n", "o", "p", "r", "s", "t", "v", "x", "y", "z",
        ],
    ))
    .chain(extract_parallel_values(
        &record,
        "611",
        "*",
        "0",
        &[
            "a", "b", "c", "d", "e", "f", "g", "k", "l", "n", "p", "q", "s", "t", "v", "x", "y",
            "z",
        ],
    ))
    .chain(extract_parallel_values(
        &record,
        "630",
        "*",
        "0",
        &[
            "a", "d", "f", "g", "k", "l", "m", "n", "o", "p", "r", "s", "t", "v", "x", "y", "z",
        ],
    ))
    .chain(extract_parallel_values(
        &record,
        "650",
        "*",
        "0",
        &["a", "b", "c", "v", "x", "y", "z"],
    ))
    .chain(extract_parallel_values(
        &record,
        "650",
        "*",
        "7",
        &["a", "b", "c", "v", "x", "y", "z"],
    ))
    .chain(extract_parallel_values(
        &record,
        "651",
        "*",
        "0",
        &["a", "v", "x", "y", "z"],
    ))
    .filter(|value| value.chars().any(is_cjk))
    .collect())
}
//adfgklmnoprstvxyz

fn extract_parallel_values<'record>(
    record: &'record Record,
    tag: &str,
    ind1: &'record str,
    ind2: &'record str,
    subfields: &'record [&str],
) -> impl Iterator<Item = String> + 'record {
    record
        .get_parallel_fields(tag)
        .into_iter()
        .filter(move |field| ind1 == "*" || ind1 == field.ind1())
        .filter(move |field| ind2 == "*" || ind2 == field.ind2())
        .map(|field| {
            field
                .subfields()
                .iter()
                .filter(|subfield| subfields.contains(&subfield.code()))
                .map(|subfield| subfield.content())
                .join(" ")
        })
}

pub fn normalize_oclc_number(string: String) -> String {
    identifier::normalize_oclc_number(&string)
}

pub fn is_oclc_number(string: String) -> bool {
    identifier::is_oclc_number(&string)
}

pub fn identifiers_of_all_versions(record_string: String) -> Result<Vec<String>, magnus::Error> {
    let record = get_record(&record_string)?;
    Ok(identifier::identifiers_of_all_versions(&record))
}

pub fn publication_statements(record_string: String) -> Result<Vec<String>, magnus::Error> {
    let record = get_record(&record_string)?;
    Ok(publication::publication_statements(&record).collect())
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
