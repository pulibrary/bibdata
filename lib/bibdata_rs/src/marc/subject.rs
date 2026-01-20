use itertools::Itertools;
use marctk::Record;

use crate::marc::trim_punctuation;

pub fn icpsr_subjects(record: &Record) -> Vec<String> {
    record
        .get_fields("650")
        .iter()
        .filter(|field| {
            field
                .first_subfield("2")
                .is_some_and(|subfield| subfield.content().trim() == "icpsr")
        })
        .map(|field| {
            field
                .get_subfields("a")
                .iter()
                .map(|subfield| subfield.content())
                .join(" ")
        })
        .map(|heading| trim_punctuation(&heading))
        .collect()
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn it_finds_icpsr_headings() {
        let record = Record::from_breaker(
            r#"=650 \7 $aAuto theft. $2 icpsr
=650 \7 $a Economic indicators.$2icpsr
=650 \0 $a Criminal statistics $z Oklahoma $z Oklahoma City."#,
        )
        .unwrap();
        assert_eq!(
            icpsr_subjects(&record),
            ["Auto theft".to_owned(), "Economic indicators".to_owned()]
        );
    }
}
