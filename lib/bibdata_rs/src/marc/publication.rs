// This module handles publication-related MARC fields like 260 and 264

use super::{
    fixed_field::dates::{DateType, EndDate},
    variable_length_field::join_subfields,
};
use itertools::Itertools;
use marctk::Record;

pub fn publication_statements(record: &Record) -> impl Iterator<Item = String> + use<'_> {
    statements_from_260(record).chain(statements_from_264(record))
}

fn statements_from_264(record: &Record) -> impl Iterator<Item = String> + use<'_> {
    record
        .extract_partial_fields("264abcefg3")
        .into_iter()
        .sorted_by(|a, b| a.ind2().cmp(b.ind2()))
        .map(|field| join_subfields(&field))
}

fn statements_from_260(record: &Record) -> impl Iterator<Item = String> + use<'_> {
    record
        .extract_partial_fields("260abcefg")
        .into_iter()
        .map(move |field| {
            let content = join_subfields(&field);
            match (DateType::from(record), EndDate::try_from(record)) {
                (DateType::ContinuousResourceCeasedPublication, Ok(end_date))
                    if content.ends_with("-") =>
                {
                    format!("{content}{end_date}")
                }
                _ => content,
            }
        })
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn it_gets_publication_statements_from_260() {
        let record =
            Record::from_breaker("=260 \\ $aMilano : $b Armenia Editore, $c 1976-1979.").unwrap();
        let mut statements = publication_statements(&record);

        assert_eq!(
            statements.next(),
            Some("Milano : Armenia Editore, 1976-1979.".to_owned())
        );
        assert_eq!(statements.next(), None);
    }

    #[test]
    fn it_adds_the_ending_year_if_260_does_not_have_one_and_publication_ceased() {
        let record = Record::from_breaker(
            "=008 911219d19912007ohufr-p-------0---a0eng-c
=260 \\ $aCincinnati, Ohio : $bAmerican Drama Institute,$cc1991-",
        )
        .unwrap();
        let mut statements = publication_statements(&record);

        assert_eq!(
            statements.next(),
            Some("Cincinnati, Ohio : American Drama Institute, c1991-2007".to_owned())
        );
        assert_eq!(statements.next(), None);
    }
}
