use marctk::{Field, Record};

use crate::{
    data_pipeline::pipe,
    marc::{
        extract_values::ExtractValues,
        string_normalize::{maybe_not_empty, trim_punctuation},
        variable_length_field::{extract_marc, join_subfields_by_code},
    },
};

fn linked_entry_subfields_a_t(field: &Field) -> Option<String> {
    let joined = join_subfields_by_code(field, &["a", "t"]);
    pipe!(trim_punctuation, maybe_not_empty)(&joined)
}

fn a_t_subfields_display(record: &Record, tag: &str, ind2s: &[&str]) -> Vec<String> {
    record
        .extract_field_values_by(
            |f| f.tag() == tag && f.ind1() == "0" && ind2s.contains(&f.ind2()),
            linked_entry_subfields_a_t,
        )
        .collect()
}

pub fn continues_display(record: &Record) -> Vec<String> {
    a_t_subfields_display(record, "780", &["0", "2"])
}
pub fn continues_in_part_display(record: &Record) -> Vec<String> {
    a_t_subfields_display(record, "780", &["1", "3"])
}
pub fn formed_from_display(record: &Record) -> Vec<String> {
    a_t_subfields_display(record, "780", &["4"])
}
pub fn absorbed_display(record: &Record) -> Vec<String> {
    a_t_subfields_display(record, "780", &["5"])
}
pub fn absorbed_in_part_display(record: &Record) -> Vec<String> {
    a_t_subfields_display(record, "780", &["6"])
}
pub fn separated_from_display(record: &Record) -> Vec<String> {
    a_t_subfields_display(record, "780", &["7"])
}

pub fn continued_by_display(record: &Record) -> Vec<String> {
    a_t_subfields_display(record, "785", &["0", "2"])
}
pub fn continued_in_part_by_display(record: &Record) -> Vec<String> {
    a_t_subfields_display(record, "785", &["1", "3"])
}
pub fn absorbed_by_display(record: &Record) -> Vec<String> {
    a_t_subfields_display(record, "785", &["4"])
}
pub fn absorbed_in_part_by_display(record: &Record) -> Vec<String> {
    a_t_subfields_display(record, "785", &["5"])
}
pub fn split_into_display(record: &Record) -> Vec<String> {
    a_t_subfields_display(record, "785", &["6"])
}
pub fn merged_to_form_display(record: &Record) -> Vec<String> {
    a_t_subfields_display(record, "785", &["7"])
}
pub fn changed_back_to_display(record: &Record) -> Vec<String> {
    a_t_subfields_display(record, "785", &["8"])
}
pub fn data_source_display(record: &Record) -> Vec<String> {
    extract_marc!("786at")(record)
        .into_iter()
        .map(|s| trim_punctuation(&s))
        .collect()
}

#[cfg(test)]
mod tests {
    use super::*;

    fn multi_relationship_record() -> Record {
        Record::from_breaker(
            "=780 00$aTimes Literary Supplement
=780 02$tWeekly Edition
=780 01$aContinues In Part
=780 03$tNature New Biology
=780 04$tFormed From
=780 05$tNature Physical Science
=780 06$tAbsorbed In Part
=780 07$tSeparated From
=785 00$tAPHA Newsletter
=785 02$tContinued By Name
=785 01$tContinued In Part By
=785 03$tContinued In Part By Multiple
=785 04$tAbsorbed By
=785 05$tAbsorbed In Part By
=785 06$tSplit Into
=785 07$tMerged To Form
=785 08$tChanged Back To",
        )
        .unwrap()
    }

    #[test]
    fn continues_display_uses_780_ind2_0_and_2() {
        let record = multi_relationship_record();
        assert_eq!(
            continues_display(&record),
            vec!["Times Literary Supplement", "Weekly Edition"]
        );
    }

    #[test]
    fn continues_in_part_display_uses_780_ind2_1_and_3() {
        let record = multi_relationship_record();
        assert_eq!(
            continues_in_part_display(&record),
            vec!["Continues In Part", "Nature New Biology"]
        );
    }

    #[test]
    fn formed_from_display_uses_780_ind2_4() {
        let record = multi_relationship_record();
        assert_eq!(formed_from_display(&record), vec!["Formed From"]);
    }

    #[test]
    fn absorbed_display_uses_780_ind2_5() {
        let record = multi_relationship_record();
        assert_eq!(absorbed_display(&record), vec!["Nature Physical Science"]);
    }

    #[test]
    fn absorbed_in_part_display_uses_780_ind2_6() {
        let record = multi_relationship_record();
        assert_eq!(absorbed_in_part_display(&record), vec!["Absorbed In Part"]);
    }

    #[test]
    fn separated_from_display_uses_780_ind2_7() {
        let record = multi_relationship_record();
        assert_eq!(separated_from_display(&record), vec!["Separated From"]);
    }

    #[test]
    fn continued_by_display_uses_785_ind2_0_and_2() {
        let record = multi_relationship_record();
        assert_eq!(
            continued_by_display(&record),
            vec!["APHA Newsletter", "Continued By Name"]
        );
    }

    #[test]
    fn continued_in_part_by_display_uses_785_ind2_1_and_3() {
        let record = multi_relationship_record();
        assert_eq!(
            continued_in_part_by_display(&record),
            vec!["Continued In Part By", "Continued In Part By Multiple"]
        );
    }

    #[test]
    fn absorbed_by_display_uses_785_ind2_4() {
        let record = multi_relationship_record();
        assert_eq!(absorbed_by_display(&record), vec!["Absorbed By"]);
    }

    #[test]
    fn absorbed_in_part_by_display_uses_785_ind2_5() {
        let record = multi_relationship_record();
        assert_eq!(
            absorbed_in_part_by_display(&record),
            vec!["Absorbed In Part By"]
        );
    }

    #[test]
    fn split_into_display_uses_785_ind2_6() {
        let record = multi_relationship_record();
        assert_eq!(split_into_display(&record), vec!["Split Into"]);
    }

    #[test]
    fn merged_to_form_display_uses_785_ind2_7() {
        let record = multi_relationship_record();
        assert_eq!(merged_to_form_display(&record), vec!["Merged To Form"]);
    }

    #[test]
    fn changed_back_to_display_uses_785_ind2_8() {
        let record = multi_relationship_record();
        assert_eq!(changed_back_to_display(&record), vec!["Changed Back To"]);
    }

    #[test]
    fn tag_780_relationships_do_not_leak_into_tag_785_and_vise_versa() {
        let record = multi_relationship_record();
        assert!(!continues_display(&record).contains(&"APHA Newsletter".to_string()));
        assert!(!continued_by_display(&record).contains(&"Times Literary Supplement".to_string()));
    }

    #[test]
    fn only_ind1_0_is_included() {
        let record = Record::from_breaker(
            "=780 00$aKeep Me
=780 10$aDrop Me
=780 20$aAlso Drop",
        )
        .unwrap();
        assert_eq!(continues_display(&record), vec!["Keep Me"]);
    }

    #[test]
    fn ignores_non_a_t_subfields() {
        let record = Record::from_breaker(
            "=780 06$tNature New Biology$w(CKB)954927601631$w(DLC)72026185$x2058-1092
=780 05$tNature Physical Science$w(CKB)958480240332$x2058-1106",
        )
        .unwrap();
        assert_eq!(
            absorbed_in_part_display(&record),
            vec!["Nature New Biology"]
        );
        assert_eq!(absorbed_display(&record), vec!["Nature Physical Science"]);
    }

    #[test]
    fn joins_a_and_t_with_single_space() {
        let record = Record::from_breaker("=780 04$aMain Title, $tSubtitle Vol. 1").unwrap();
        assert_eq!(
            formed_from_display(&record),
            vec!["Main Title, Subtitle Vol. 1"]
        );
    }

    #[test]
    fn trims_trailing_punctuation() {
        let record = Record::from_breaker(
            "=780 00$aTimes Literary Supplement :
=780 02$tWeekly Edition.",
        )
        .unwrap();
        assert_eq!(
            continues_display(&record),
            vec!["Times Literary Supplement", "Weekly Edition"]
        );
    }

    #[test]
    fn empty_subfields_are_omitted() {
        let record = Record::from_breaker(
            "=780 00$w(CKB)123
=780 00$tReal Title",
        )
        .unwrap();
        assert_eq!(continues_display(&record), vec!["Real Title"]);
    }

    #[test]
    fn no_matching_fields_yields_empty_vec() {
        let record = Record::from_breaker("=245 10$aAn Unrelated Title").unwrap();
        assert_eq!(continues_display(&record), Vec::<String>::new());
        assert_eq!(changed_back_to_display(&record), Vec::<String>::new());
    }

    #[test]
    fn handles_non_latin_titles() {
        let record = Record::from_breaker("=785 08$t日本語のタイトル").unwrap();
        assert_eq!(changed_back_to_display(&record), vec!["日本語のタイトル"]);
    }

    #[test]
    fn data_source_display_uses_786_a_and_t() {
        let record = Record::from_breaker("=786 00$aData Source Title, $tSubtitle").unwrap();
        assert_eq!(
            data_source_display(&record),
            vec!["Data Source Title, Subtitle"]
        );
    }

    #[test]
    fn data_source_display_trims_punctuation() {
        let record = Record::from_breaker("=786 00$aSource : $tVolume One.").unwrap();
        assert_eq!(data_source_display(&record), vec!["Source : Volume One"]);
    }
}
