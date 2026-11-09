use crate::marc::variable_length_field::join_all_subfields;
use marctk::Record;

pub mod action_note;

pub fn access_notes(record: &Record) -> Option<Vec<String>> {
    let notes: Vec<String> = record
        .extract_values("506(1*)a")
        .iter()
        .map(|note| note.trim().to_owned())
        .collect();
    if notes.is_empty() { None } else { Some(notes) }
}

/// Cumulative index note: MARC 555 with a blank first indicator.
/// (Indicator 1 = 0 is a finding aid, 8 is "not specified".)
pub fn indexes_display(record: &Record) -> Vec<String> {
    record
        .extract_partial_fields("555(_*)3abcd")
        .iter()
        .map(join_all_subfields)
        .filter(|note| !note.is_empty())
        .collect()
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn it_finds_access_notes_when_restrictions_apply() {
        let record = Record::from_breaker(
            r"=506 1\ $3 Princeton copy 1 $a For conservation reasons, access is granted for compelling reasons only: please consult the curator of the Cotsen Children's Library. $5 NjP"
        ).unwrap();

        let access_notes = access_notes(&record);
        assert_eq!(
            access_notes.unwrap(),
            vec!["For conservation reasons, access is granted for compelling reasons only: please consult the curator of the Cotsen Children's Library.".to_owned()]
        );
    }

    #[test]
    fn it_does_not_include_access_notes_when_unrestricted() {
        let record = Record::from_breaker(
            r"=506 0\ $aAccess copy available to the general public.$fUnrestricted$2star$5MH",
        )
        .unwrap();

        assert!(access_notes(&record).is_none());
    }

    #[test]
    fn it_indexes_cumulative_index_notes_with_blank_first_indicator() {
        let record = Record::from_breaker(r"=555 \\$a Vols. 1 (1978)-17 (1995/96). 1 v.").unwrap();

        assert_eq!(
            indexes_display(&record),
            vec!["Vols. 1 (1978)-17 (1995/96). 1 v.".to_owned()]
        );
    }

    #[test]
    fn it_excludes_finding_aid_and_not_specified_555() {
        let record = Record::from_breaker(
            r"=555 0\$a Finding aid to the Queer zine collection
=555 8\$a Not specified content",
        )
        .unwrap();

        assert!(indexes_display(&record).is_empty());
    }

    #[test]
    fn it_indexes_multiple_blank_indicator_555_fields_in_order() {
        let record = Record::from_breaker(
            r"=555 \\$a Cumulative index for the first series
=555 \\$b Cumulative index for the second series",
        )
        .unwrap();

        assert_eq!(
            indexes_display(&record),
            vec![
                "Cumulative index for the first series".to_owned(),
                "Cumulative index for the second series".to_owned(),
            ]
        );
    }

    #[test]
    fn it_joins_listed_subfields_and_ignores_others() {
        let record = Record::from_breaker(
            r"=555 \\$3 Ephemera Dept $a Cumulative index $b 1900-1950 $c in 3 vols $d 1950 $e Should be dropped",
        )
        .unwrap();

        assert_eq!(
            indexes_display(&record),
            vec!["Ephemera Dept Cumulative index 1900-1950 in 3 vols 1950".to_owned()]
        );
    }

    #[test]
    fn it_drops_blank_indicator_555_with_no_index_subfields() {
        let record = Record::from_breaker(r"=555 \\$5 NjP").unwrap();

        assert!(indexes_display(&record).is_empty());
    }

    #[test]
    fn it_returns_empty_when_there_is_no_blank_indicator_555() {
        let record = Record::from_breaker(r"=245 10$aSome Title").unwrap();

        assert!(indexes_display(&record).is_empty());
    }

    #[test]
    fn it_preserves_unicode_and_non_latin_content() {
        let record =
            Record::from_breaker(r"=555 \\$a 索引 pour les 龙: volumes 1–3 $b 三").unwrap();

        assert_eq!(
            indexes_display(&record),
            vec!["索引 pour les 龙: volumes 1–3 三".to_owned()]
        );
    }
}
