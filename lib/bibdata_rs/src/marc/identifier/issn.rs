use library_stdnums::{issn::ISSN, traits::Normalize};
use marctk::Record;

pub fn normalized_issns_for_all_versions(record: &Record) -> impl Iterator<Item = String> {
    record
        .extract_values("022alyz:776x")
        .into_iter()
        .filter_map(|value| ISSN::new(value).normalize())
}
