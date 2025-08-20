use library_stdnums::{isbn::ISBN, traits::Normalize};
use marctk::Record;

pub fn normalized_isbns_for_all_versions(record: &Record) -> impl Iterator<Item = String> {
    record
        .extract_values("020az:776z")
        .into_iter()
        .filter_map(|value| ISBN::new(value).normalize())
}
