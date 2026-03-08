use itertools::Itertools;
use marctk::{Field, Record, Subfield};

use crate::marc::extract_values::ExtractValues;

pub fn extract_values_by_tag_including_non_latin<'a, T, E>(
    record: &'a Record,
    tags: &[&str],
    extractor: E,
) -> impl Iterator<Item = T>
where
    E: Fn(&'a Field) -> Option<T>,
{
    record.extract_field_values_by(
        move |field| {
            tags.iter()
                .any(|tag| *tag == field.tag() || multiscript_tag_eq(field, tag))
        },
        extractor,
    )
}

pub fn multiscript_tag_eq(field: &Field, tag: &str) -> bool {
    field.tag() == tag
        || (field.tag() == "880"
            && field
                .first_subfield("6")
                .is_some_and(|subfield| subfield.content().trim().starts_with(tag)))
}

pub fn join_all_subfields(field: &Field) -> String {
    join_subfields(field.subfields().iter())
}

pub fn join_subfields<'a>(subfields: impl Iterator<Item = &'a Subfield>) -> String {
    let raw = subfields.map(|subfield| subfield.content()).join(" ");
    combine_consecutive_whitespace(&raw)
}

fn combine_consecutive_whitespace(original: &str) -> String {
    original.split_whitespace().join(" ")
}

#[cfg(test)]
mod tests {
    use super::*;
    #[test]
    fn it_can_combine_consecutive_whitespace() {
        let s = "Dogs       cats";
        assert_eq!(combine_consecutive_whitespace(s), "Dogs cats");
    }
}
