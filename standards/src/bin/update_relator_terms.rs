use crate::UpdateRelatorTermsError::Parsing;
use std::{collections::BTreeMap, error::Error, fmt::Display, fs::File, io};

/// This binary is responsible for updating the list of relator terms (how a person
/// is related to a work) in this repo.  It downloads the list from Library of Congress
/// and saves it as JSON
/// To generate the relator_terms.json file run:
/// cargo run -p standards --bin update_relator_terms
fn main() {
    let terms = download_terms().expect("Could not download terms");
    let parsed = parse_terms(&terms).expect("Could not parse terms");
    write_serialized(&parsed).expect("Could not serialize+write");
}

const RELATOR_TERMS_URL: &str = "https://id.loc.gov/vocabulary/relators.tsv";

fn download_terms() -> Result<String, UpdateRelatorTermsError> {
    let client = reqwest::blocking::Client::builder()
        .user_agent("Update-Relator-Terms")
        .build()
        .unwrap();
    client
        .get(RELATOR_TERMS_URL)
        .send()
        .and_then(|response| response.text())
        .map_err(UpdateRelatorTermsError::Downloading)
}

fn parse_terms(original: &str) -> Result<BTreeMap<String, String>, UpdateRelatorTermsError> {
    // BTreeMap has the benefit that it is serialized alphabetically!
    let mut hash = BTreeMap::new();
    let mut rdr = csv::ReaderBuilder::new()
        .delimiter(b'\t')
        .from_reader(original.as_bytes());
    for result in rdr.records() {
        let record = result.map_err(Parsing)?;
        let code = record.get(1).unwrap().to_owned();
        let term = record.get(2).unwrap().to_owned();
        hash.insert(code, term);
    }
    Ok(hash)
}

fn write_serialized(terms: &BTreeMap<String, String>) -> Result<(), UpdateRelatorTermsError> {
    let writer = File::create(format!(
        "{}/data/relator_terms.json",
        env!("CARGO_MANIFEST_DIR")
    ))
    .map_err(UpdateRelatorTermsError::Disk)?;
    serde_json::to_writer_pretty(writer, terms).map_err(UpdateRelatorTermsError::Serialization)
}

#[derive(Debug)]
enum UpdateRelatorTermsError {
    Downloading(reqwest::Error),
    Parsing(csv::Error),
    Serialization(serde_json::Error),
    Disk(io::Error),
}

impl Display for UpdateRelatorTermsError {
    fn fmt(&self, f: &mut std::fmt::Formatter) -> std::fmt::Result {
        write!(f, "{:?}", self)
    }
}

impl Error for UpdateRelatorTermsError {
    fn source(&self) -> Option<&(dyn Error + 'static)> {
        match self {
            Self::Downloading(err) => Some(err),
            Self::Parsing(err) => Some(err),
            Self::Serialization(err) => Some(err),
            Self::Disk(err) => Some(err),
        }
    }
}
