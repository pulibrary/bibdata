use marctk::Record;

use crate::marc::holdings::holding_location::{library_label, location_codes};

/// Iterate through the names of Libraries that have holdings on this record
pub fn location_facet(record: &Record) -> Option<Vec<String>> {
    let library_names: Vec<String> = location_codes(record)
        .iter()
        .filter_map(|location_code| library_label(location_code))
        .filter(|library_label| *library_label != "Online")
        .map(String::from)
        .collect();
    if library_names.is_empty() {
        None
    } else {
        Some(library_names)
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn it_gets_the_locations() {
        let record = Record::from_breaker("=852 00$bmarquand$cstacks$822614080750006421").unwrap();
        assert_eq!(
            location_facet(&record),
            Some(vec![String::from("Marquand Library")])
        )
    }
}
