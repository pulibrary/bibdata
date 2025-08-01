use magnus::exception;
use marctk::Record;

mod string_normalize;

pub mod fixed_field;
pub mod genre;
pub mod language;

pub use string_normalize::trim_punctuation;

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
