use crate::marc::trim_punctuation;
use marctk::Record;
use std::collections::HashSet;

pub enum BiographicalContent {
    Biography,
    Autobiography,
    NotBiography,
}

impl From<&Record> for BiographicalContent {
    fn from(value: &Record) -> Self {
        match (biography(value), author_matches_subject(value)) {
            (true, true) => Self::Autobiography,
            (true, false) => Self::Biography,
            _ => Self::NotBiography,
        }
    }
}

fn biography(value: &Record) -> bool {
    (value
        .extract_values("600(*0)vx:610(*0)vx:611(*0)vx:630(*0)vx:650(*0)avx:651(*0)vx:655(*0)avx"))
    .iter()
    .any(|s| s == "Biography")
}

fn author_matches_subject(record: &Record) -> bool {
    let mut authors = record
        .extract_values("100abcdjq")
        .into_iter()
        .map(|author| trim_punctuation(author.to_lowercase().trim()));
    let name_subjects = record
        .extract_values("600abcdjq")
        .iter()
        .map(|author| trim_punctuation(author.to_lowercase().trim()))
        .collect::<HashSet<_>>();
    authors.any(|author| name_subjects.contains(&author))
}
