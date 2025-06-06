use magnus::exception;
use marctk::Record;

mod punctuation;

pub mod fixed_field;
pub mod genre;

pub use punctuation::trim_punctuation;

pub fn genres(xml: String) -> Result<Vec<String>, magnus::Error> {
    let record = get_record(&xml)?;
    Ok(genre::genres(&record))
}

fn get_record(breaker: &str) -> Result<Record, magnus::Error> {
    Record::from_breaker(breaker).map_err(|err| {
        magnus::Error::new(
            exception::runtime_error(),
            format!("Found error {} while parsing breaker {}", err, breaker),
        )
    })
}
