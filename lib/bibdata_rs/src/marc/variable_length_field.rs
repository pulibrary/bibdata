use itertools::Itertools;
use marctk::{Field, Subfield};

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
