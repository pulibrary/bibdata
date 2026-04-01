// This module handles publication-related MARC fields like 260 and 264

use crate::marc::{
    extract_values::ExtractValues, trim_punctuation,
    variable_length_field::latin_or_non_latin_tag_included_in,
};

use super::{
    fixed_field::dates::{DateType, EndDate},
    variable_length_field::{join_all_subfields, join_subfields},
};
use itertools::Itertools;
use marctk::Record;

pub fn pub_created_display(record: &Record) -> impl Iterator<Item = String> + use<'_> {
    statements_from_260(record)
        .chain(statements_from_parallel_260(record))
        .chain(statements_from_264(record))
        .chain(statements_from_parallel_264(record))
}

pub fn pub_citation_display(record: &Record) -> impl Iterator<Item = String> {
    record
        .extract_field_values_by(
            latin_or_non_latin_tag_included_in(&["260", "264"]),
            |field| {
                let place = field.first_subfield("a");
                let name = field.first_subfield("b");
                match (place, name) {
                    (Some(place), None) => Some(trim_punctuation(place.content())),
                    (None, Some(name)) => Some(trim_punctuation(name.content())),
                    (Some(place), Some(name)) => Some(format!(
                        "{}: {}",
                        trim_punctuation(place.content()),
                        trim_punctuation(name.content())
                    )),
                    _ => None,
                }
            },
        )
        .unique()
}

fn statements_from_264(record: &Record) -> impl Iterator<Item = String> + use<'_> {
    record
        .extract_partial_fields("264abcefg3")
        .into_iter()
        .sorted_by(|a, b| a.ind2().cmp(b.ind2()))
        .map(|field| join_all_subfields(&field))
}

fn statements_from_260(record: &Record) -> impl Iterator<Item = String> + use<'_> {
    record
        .extract_partial_fields("260abcefg")
        .into_iter()
        .map(move |field| {
            let content = join_all_subfields(&field);
            append_end_date_if_needed(&content, record)
        })
}

fn statements_from_parallel_264(record: &Record) -> impl Iterator<Item = String> + use<'_> {
    record
        .get_parallel_fields("264")
        .into_iter()
        .map(move |field| {
            let content =
                join_subfields(field.subfields().iter().filter(|subfield| {
                    ["a", "b", "c", "e", "f", "g", "3"].contains(&subfield.code())
                }));
            append_end_date_if_needed(&content, record)
        })
}

fn statements_from_parallel_260(record: &Record) -> impl Iterator<Item = String> + use<'_> {
    record
        .get_parallel_fields("260")
        .into_iter()
        .map(move |field| {
            let content = join_subfields(
                field
                    .subfields()
                    .iter()
                    .filter(|subfield| ["a", "b", "c", "e", "f", "g"].contains(&subfield.code())),
            );
            append_end_date_if_needed(&content, record)
        })
}

fn append_end_date_if_needed(publication_statement: &str, record: &Record) -> String {
    match (DateType::from(record), EndDate::try_from(record)) {
        (DateType::ContinuousResourceCeasedPublication, Ok(end_date))
            if publication_statement.ends_with("-") =>
        {
            format!("{publication_statement}{end_date}")
        }
        _ => publication_statement.to_owned(),
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn it_gets_publication_statements_from_260() {
        let record =
            Record::from_breaker("=260 \\ $aMilano : $b Armenia Editore, $c 1976-1979.").unwrap();
        let mut statements = pub_created_display(&record);

        assert_eq!(
            statements.next(),
            Some("Milano : Armenia Editore, 1976-1979.".to_owned())
        );
        assert_eq!(statements.next(), None);
    }

    #[test]
    fn it_gets_parallel_publication_statements_in_non_latin_script_from_260() {
        let record =
            Record::from_breaker("=245 00 $6880-01$a2006-2025 Sŏul, tosi kŏnch'uk hyŏksin ŭi kirok : ilsang ŭl pit naenŭn Sŏul ŭi tosi kŏnch'uk p'ŭrojekt'ŭ 66.
=880 00 $6245-01$a2006-2025 서울, 도시건축 혁신의 기록 : 일상을 빛내는 서울의 도시건축 프로젝트 66.
=260 \\ $6880-02$a Sŏul: $b Sŏul T'ŭkpyŏlsi, $c 2025.
=880 \\ $6260-02$a 서울: $b 서울특별시, $c 2025.").unwrap();
        let mut statements = pub_created_display(&record);

        assert_eq!(
            statements.next(),
            Some("Sŏul: Sŏul T'ŭkpyŏlsi, 2025.".to_owned())
        );
        assert_eq!(
            statements.next(),
            Some("서울: 서울특별시, 2025.".to_owned())
        );
        assert_eq!(statements.next(), None);
    }

    #[test]
    fn it_gets_parallel_publication_statements_in_non_latin_script_from_264() {
        let record =
            Record::from_breaker(r"=245 00 $6880-01$a Mahākālera tarjanī : $b Baṅgabandhu Śekha Mujibake nibedita kabitā / $c sampādanā, Kāmāla Caudhurī = Mohakaler torjoni : Bangabandhu Sheikh Mujibke nibedito kobita.
=880 00 $6245-01$aমহাকালের তর্জনী : $b বঙ্গবন্ধু শেখ মুজিবকে নিবেদিত কবিতা / $c সম্পাদনা, কামাল চৌধুরী = Mohakaler torjoni : Bangabandhu Sheikh Mujibke nibedito kobita.
=264 \1 $6880-02$a Ḍhākā : $b Di Iunibhārsiṭi Presa Limiṭeḍa, $c Mārca 2022.
=880 \1 $6264-02$a ঢাকা : $b ডি ইউনিভার্সিটি প্রেস লিমিটেড, $c মার্চ ২০২২.").unwrap();
        let mut statements = pub_created_display(&record);

        assert_eq!(
            statements.next(),
            Some("Ḍhākā : Di Iunibhārsiṭi Presa Limiṭeḍa, Mārca 2022.".to_owned())
        );
        assert_eq!(
            statements.next(),
            Some("ঢাকা : ডি ইউনিভার্সিটি প্রেস লিমিটেড, মার্চ ২০২২.".to_owned())
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
        let mut statements = pub_created_display(&record);

        assert_eq!(
            statements.next(),
            Some("Cincinnati, Ohio : American Drama Institute, c1991-2007".to_owned())
        );
        assert_eq!(statements.next(), None);
    }

    #[test]
    fn it_can_create_a_publisher_citation_with_a_place() {
        let record = Record::from_breaker(
            r#"=260 \\ $a Princeton
=264 \\ $a Brooklyn"#,
        )
        .unwrap();
        let mut publisher_citations = pub_citation_display(&record);
        assert_eq!(publisher_citations.next(), Some("Princeton".to_string()));
        assert_eq!(publisher_citations.next(), Some("Brooklyn".to_string()));
        assert!(publisher_citations.next().is_none());
    }

    #[test]
    fn it_can_create_a_publisher_citation_with_a_name() {
        let record = Record::from_breaker(
            r#"=260 \\ $b Princeton University Press
=264 \\ $b Archipelago Books"#,
        )
        .unwrap();
        let mut publisher_citations = pub_citation_display(&record);
        assert_eq!(
            publisher_citations.next(),
            Some("Princeton University Press".to_string())
        );
        assert_eq!(
            publisher_citations.next(),
            Some("Archipelago Books".to_string())
        );
        assert!(publisher_citations.next().is_none());
    }

    #[test]
    fn it_can_create_a_publisher_citation_with_a_place_and_a_name() {
        let record = Record::from_breaker(
            r#"=260 \\ $a Princeton : $b Princeton University Press
=264 \\ $a Brooklyn $b Archipelago Books"#,
        )
        .unwrap();
        let mut publisher_citations = pub_citation_display(&record);
        assert_eq!(
            publisher_citations.next(),
            Some("Princeton: Princeton University Press".to_string())
        );
        assert_eq!(
            publisher_citations.next(),
            Some("Brooklyn: Archipelago Books".to_string())
        );
        assert!(publisher_citations.next().is_none());
    }

    #[test]
    fn it_can_create_a_non_latin_publisher_citation() {
        let record = Record::from_breaker(
            r#"=264 \1 $6 880-04 $a Kunming : $b Yunnan da xue chu ban she, $c 2014.
=880 \1 $6 264-04 $a 昆明 : $b 云南大学出版社, $c 2014."#,
        )
        .unwrap();
        let mut publisher_citations = pub_citation_display(&record);
        assert_eq!(
            publisher_citations.next(),
            Some("Kunming: Yunnan da xue chu ban she".to_string())
        );
        assert_eq!(
            publisher_citations.next(),
            Some("昆明: 云南大学出版社".to_string())
        );
        assert!(publisher_citations.next().is_none());
    }
}
