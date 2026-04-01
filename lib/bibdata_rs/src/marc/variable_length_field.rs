use itertools::Itertools;
use marctk::{Field, Subfield};

pub trait SubfieldIterator<'a>: Iterator<Item = &'a Subfield> {
    fn content(self) -> impl Iterator<Item = &'a str>;
    fn filter_by_code(self, codes: &'a [&str]) -> impl Iterator<Item = &'a Subfield>;
    fn subfields_before(self, stop_before: &'a str) -> impl Iterator<Item = &'a Subfield>;
}
impl<'a, I> SubfieldIterator<'a> for I
where
    I: Iterator<Item = &'a Subfield>,
{
    fn content(self) -> impl Iterator<Item = &'a str> {
        self.map(|subfield| subfield.content())
    }
    fn filter_by_code(self, codes: &'a [&str]) -> impl Iterator<Item = &'a Subfield> {
        self.filter(move |subfield| codes.contains(&subfield.code()))
    }

    fn subfields_before(self, stop_before: &'a str) -> impl Iterator<Item = &'a Subfield> {
        self.take_while(move |subfield| subfield.code() != stop_before)
    }
}

pub fn latin_or_non_latin_tag_included_in(tags: &[&str]) -> impl Fn(&Field) -> bool {
    |field| tags.contains(&field.tag()) || non_latin_tag_included_in(tags)(field)
}

pub fn non_latin_tag(field: &Field) -> Option<&str> {
    if field.tag() != "880" {
        return None;
    };
    field
        .first_subfield("6")
        .map(|subfield| subfield.content().trim())
        .and_then(|raw| raw.get(0..3))
}

pub fn non_latin_tag_included_in(tags: &[&str]) -> impl Fn(&Field) -> bool {
    move |field| non_latin_tag(field).is_some_and(|field_tag| tags.contains(&field_tag))
}

pub fn join_all_subfields(field: &Field) -> String {
    join_subfields(field.subfields().iter())
}

pub fn join_subfields_except(field: &Field, exclude: &[&str]) -> String {
    join_subfields(
        field
            .subfields()
            .iter()
            .filter(|subfield| !exclude.contains(&subfield.code())),
    )
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

    #[test]
    fn it_can_find_multiscript_tag() {
        let mut field = Field::new("880").unwrap();
        field.add_subfield("6", "111-01").unwrap();
        assert_eq!(non_latin_tag(&field), Some("111"));
    }

    #[test]
    fn it_can_take_subfields_before() {
        let mut field = Field::new("123").unwrap();
        field.add_subfield("a", "dolphin").unwrap();
        field.add_subfield("z", "whale").unwrap();
        field.add_subfield("t", "STOP STOP STOP").unwrap();
        field.add_subfield("b", "orca").unwrap();

        let before_t: String = field
            .subfields()
            .iter()
            .subfields_before("t")
            .content()
            .collect();
        assert_eq!(before_t, "dolphinwhale");
    }
}
