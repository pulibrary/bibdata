use marctk::Record;
use crate::marc::{cjk::has_cjk_chars, extract_values::ExtractValues, variable_length_field::join_subfields_except};

/// This module is responsible for fields that contain text in
/// non-Latin and non-CJK languages


pub fn non_latin_non_cjk_all(record: &Record) -> impl Iterator<Item = String> {
    record.extract_field_values_by(
        |field| field.tag() == "880",
        |field| {
            let joined = join_subfields_except(field, &["6"]);
            if !has_cjk_chars(&joined) && !joined.is_empty() {
                Some(joined)
            } else {
                None
            }
        },
    )
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn it_indexes_fields_that_are_not_in_a_cjk_language() {
let record = Record::from_breaker(
            r#"=880 \\$6123-01$a돌고래
=880 \\$6123-02$aدُلفين"#,
        )
        .unwrap();
        let mut cjk_all = non_latin_non_cjk_all(&record);
        assert_eq!(cjk_all.next(), Some(String::from("دُلفين")));
        assert_eq!(cjk_all.next(), None);
    }
}
