use library_stdnums::{isbn::ISBN, issn::ISSN, lccn::LCCN, traits::Normalize};
use marctk::Record;

pub fn normalized_isbns(record: &Record) -> impl Iterator<Item = String> {
    record
        .extract_values("020a")
        .into_iter()
        .filter_map(|isbn| ISBN::new(isbn).normalize())
}

pub fn normalized_issns(record: &Record) -> impl Iterator<Item = String> {
    record
        .extract_values("022a")
        .into_iter()
        .filter_map(|issn| ISSN::new(issn).normalize())
}

pub fn normalized_lccns(record: &Record) -> impl Iterator<Item = String> {
    record
        .extract_values("010a")
        .into_iter()
        .filter_map(|lccn| LCCN::new(lccn).normalize())
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn it_can_find_isbns() {
        let record = Record::from_breaker("=020 \\$a9780063070875 $q (hardcover)").unwrap();
        let mut isbns = normalized_isbns(&record);
        assert_eq!(isbns.next(), Some(String::from("9780063070875")));
        assert_eq!(isbns.next(), None);
    }

    #[test]
    fn it_can_find_issns() {
        let record = Record::from_breaker("=022 \\$a1608-1439").unwrap();
        let mut issns = normalized_issns(&record);
        assert_eq!(issns.next(), Some(String::from("16081439")));
        assert_eq!(issns.next(), None);
    }

    #[test]
    fn it_can_find_lccns() {
        let record = Record::from_breaker("=010 \\$an  98045678").unwrap();
        let mut lccns = normalized_lccns(&record);
        assert_eq!(lccns.next(), Some(String::from("n98045678")));
        assert_eq!(lccns.next(), None);
    }
}
