use crate::marc::string_normalize::maybe_not_empty;
use itertools::Itertools;
use marctk::{Field, Subfield};

pub trait SubfieldIterator<'a>: Iterator<Item = &'a Subfield> {
    fn content(self) -> impl Iterator<Item = &'a str>;
    fn join(self, delimiter: &'a str) -> String;
    fn filter_by_code(self, codes: &'a [&str]) -> impl Iterator<Item = &'a Subfield>;
    fn subfields_before(self, stop_before: &'a str) -> impl Iterator<Item = &'a Subfield>;
    fn subfields_after(self, start_at: &'a str) -> impl Iterator<Item = &'a Subfield>;
}
impl<'a, I> SubfieldIterator<'a> for I
where
    I: Iterator<Item = &'a Subfield>,
{
    fn content(self) -> impl Iterator<Item = &'a str> {
        self.map(|subfield| subfield.content())
    }
    fn join(self, delimiter: &'a str) -> String {
        self.content().join(delimiter)
    }
    fn filter_by_code(self, codes: &'a [&str]) -> impl Iterator<Item = &'a Subfield> {
        self.filter(move |subfield| codes.contains(&subfield.code()))
    }

    fn subfields_before(self, stop_before: &'a str) -> impl Iterator<Item = &'a Subfield> {
        self.take_while(move |subfield| subfield.code() != stop_before)
    }

    fn subfields_after(self, start_at: &'a str) -> impl Iterator<Item = &'a Subfield> {
        self.skip_while(move |subfield| subfield.code() != start_at)
    }
}

pub fn latin_tag_included_in(tags: &[&str]) -> impl Fn(&Field) -> bool {
    |field| tags.contains(&field.tag())
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

pub fn join_subfields_by_code(field: &Field, include: &[&str]) -> String {
    join_subfields(filter_subfields(field, |subfield| {
        include.contains(&subfield.code())
    }))
}

pub fn join_subfields_except(field: &Field, exclude: &[&str]) -> String {
    join_subfields(filter_subfields(field, |subfield| {
        !exclude.contains(&subfield.code())
    }))
}

fn filter_subfields(
    field: &Field,
    filter: impl Fn(&&Subfield) -> bool,
) -> impl Iterator<Item = &Subfield> {
    field.subfields().iter().filter(filter)
}

pub fn join_subfields<'a>(subfields: impl Iterator<Item = &'a Subfield>) -> String {
    let raw = subfields.map(|subfield| subfield.content()).join(" ");
    combine_consecutive_whitespace(&raw)
}

fn combine_consecutive_whitespace(original: &str) -> String {
    original.split_whitespace().join(" ")
}

#[derive(Debug, PartialEq)]
pub struct ExtractSpec<'a> {
    tag: &'a str,
    subfields: Vec<&'a str>,
}

impl<'a> ExtractSpec<'a> {
    pub fn get_subfields(&'a self, field: &'a Field) -> Option<String> {
        if self.tag_matcher(field) {
            maybe_not_empty(join_subfields_by_code(field, &self.subfields))
        } else {
            None
        }
    }

    pub fn tag_matcher(&self, field: &Field) -> bool {
        latin_or_non_latin_tag_included_in(&[self.tag])(field)
    }
}

#[derive(Debug, PartialEq)]
pub struct IncorrectExtractSpec {}
impl<'a> TryFrom<&'a str> for ExtractSpec<'a> {
    type Error = IncorrectExtractSpec;

    fn try_from(value: &'a str) -> Result<Self, Self::Error> {
        let length = value.len();
        if length < 3 {
            return Err(IncorrectExtractSpec {});
        }
        let mut subfields = Vec::new();
        for i in 3..length {
            subfields.push(value.get(i..i + 1).unwrap());
        }
        Ok(ExtractSpec {
            tag: value.get(0..3).expect("Extract spec is not 3 bytes!"),
            subfields,
        })
    }
}

/// This macro can be used similarly to the traject extract_marc macro:
/// `extract_marc!("245abc", "100a");` will return a closure that you can
/// call to extract the desired fields from a record.
macro_rules! extract_marc {
    ( $( $spec:expr),+ ) => {{
        use crate::marc::variable_length_field::ExtractSpec;
        use crate::marc::extract_values::ExtractValues;
        use marctk::Record;

        let mut specs = Vec::new();
        $(
            specs.push(ExtractSpec::try_from($spec).unwrap());
        )+
        move |record: &Record| {
            record
                .extract_field_values_by(
                    |field| specs.iter().any(|spec| spec.tag_matcher(field)),
                    |field| specs.iter().map(|spec| spec.get_subfields(field)).flatten().next())
                .collect::<Vec<String>>()
        }
    }};
}

pub(crate) use extract_marc;

#[cfg(test)]
mod tests {
    use marctk::Record;

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

    #[test]
    fn it_can_take_subfields_after() {
        let mut field = Field::new("123").unwrap();
        field.add_subfield("a", "dolphin").unwrap();
        field.add_subfield("z", "whale").unwrap();
        field.add_subfield("t", "squid").unwrap();
        field.add_subfield("b", "orca").unwrap();

        let after_t: String = field
            .subfields()
            .iter()
            .subfields_after("t")
            .content()
            .collect();
        assert_eq!(after_t, "squidorca");
    }

    #[test]
    fn it_can_make_an_extract_spec() {
        let expected = ExtractSpec {
            tag: "245",
            subfields: vec!["a", "b", "c"],
        };
        assert_eq!(ExtractSpec::try_from("245abc"), Ok(expected))
    }

    #[test]
    fn extract_marc_macro() {
        let record = Record::from_breaker(
            r#"=100 \\$aDog
=245 \\$aHello$bHi$cGoodbye"#,
        )
        .unwrap();
        let extractor = extract_marc!("100a", "245abc");
        assert_eq!(
            extractor(&record),
            vec![String::from("Dog"), String::from("Hello Hi Goodbye")]
        );
    }
}
