use crate::marc::{extract_values::ExtractValues, string_normalize::maybe_not_empty};
use itertools::Itertools;
use marctk::{Field, Record, Subfield};

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
pub enum ScriptsToIndex {
    All,
    LatinOnly,
    NonLatinOnly,
}

#[derive(Debug, PartialEq)]
pub struct ExtractSpec<'a> {
    tag: &'a str,
    subfields: Vec<&'a str>,
    scripts: ScriptsToIndex,
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
        match self.scripts {
            ScriptsToIndex::All => latin_or_non_latin_tag_included_in(&[self.tag])(field),
            ScriptsToIndex::LatinOnly => latin_tag_included_in(&[self.tag])(field),
            ScriptsToIndex::NonLatinOnly => non_latin_tag_included_in(&[self.tag])(field),
        }
    }

    pub fn new(spec: &'a str, scripts: ScriptsToIndex) -> Result<Self, IncorrectExtractSpec> {
        let length = spec.len();
        if length < 3 {
            return Err(IncorrectExtractSpec {});
        }
        let mut subfields = Vec::new();
        for i in 3..length {
            subfields.push(spec.get(i..i + 1).unwrap());
        }
        Ok(ExtractSpec {
            tag: spec.get(0..3).expect("Extract spec is not 3 bytes!"),
            subfields,
            scripts,
        })
    }
}

#[derive(Debug, PartialEq)]
pub struct IncorrectExtractSpec {}

/// This macro can be used similarly to the traject extract_marc macro:
/// `extract_marc!("245abc", "100a");` will return a closure that you can
/// call to extract the desired fields from a record.
macro_rules! extract_marc {
    ( latin $( $spec:expr),+ ) => {{
        use crate::marc::variable_length_field::{ExtractSpec, ScriptsToIndex, extract_marc_impl};
        extract_marc_impl(vec![$(ExtractSpec::new($spec, ScriptsToIndex::LatinOnly).unwrap()),+])
    }};
    ( non_latin $( $spec:expr),+ ) => {{
        use crate::marc::variable_length_field::{ExtractSpec, ScriptsToIndex, extract_marc_impl};
        extract_marc_impl(vec![$(ExtractSpec::new($spec, ScriptsToIndex::NonLatinOnly).unwrap()),+])
    }};
    ( $( $spec:expr),+ ) => {{
        use crate::marc::variable_length_field::{ExtractSpec, ScriptsToIndex, extract_marc_impl};
        extract_marc_impl(vec![$(ExtractSpec::new($spec, ScriptsToIndex::All).unwrap()),+])
    }};
}

pub fn extract_marc_impl<'a>(
    specs: Vec<ExtractSpec<'_>>,
) -> impl Fn(&'a Record) -> Vec<String> + use<'a, '_> {
    move |record: &'a Record| {
        record
            .extract_field_values_by(
                |field| specs.iter().any(|spec| spec.tag_matcher(field)),
                |field| {
                    specs
                        .iter()
                        .filter_map(|spec| spec.get_subfields(field))
                        .next()
                },
            )
            .collect::<Vec<String>>()
    }
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
            scripts: ScriptsToIndex::All,
        };
        assert_eq!(
            ExtractSpec::new("245abc", ScriptsToIndex::All),
            Ok(expected)
        )
    }

    #[test]
    fn extract_marc_macro_returns_latin_and_non_latin_by_default() {
        let record = Record::from_breaker(r#"=245 00 $6880-01 $a Kirin malgo kirin : $b 2023 Yangju Sirip Hoeam Saji Pangmulgwan t'ŭkpyŏl chŏnsi = Not giraffe but qilin : 2023 Hoeamsaji Museum of Yangju City spcial exhibition.
=880 00 $6245-01 $a 기린 말고 기린 : $b 2023 양주 시립 회암 사지 박물관 특별 전시 = Not giraffe but qilin : 2023 Hoeamsaji Museum of Yangju City spcial exhibition."#).unwrap();
        assert_eq!(
            extract_marc!("245a")(&record),
            vec![
                String::from("Kirin malgo kirin :"),
                String::from("기린 말고 기린 :")
            ]
        );
    }

    #[test]
    fn extract_marc_macro_can_return_just_latin() {
        let record = Record::from_breaker(r#"=245 00 $6880-01 $a Kirin malgo kirin : $b 2023 Yangju Sirip Hoeam Saji Pangmulgwan t'ŭkpyŏl chŏnsi = Not giraffe but qilin : 2023 Hoeamsaji Museum of Yangju City spcial exhibition.
=880 00 $6245-01 $a 기린 말고 기린 : $b 2023 양주 시립 회암 사지 박물관 특별 전시 = Not giraffe but qilin : 2023 Hoeamsaji Museum of Yangju City spcial exhibition."#).unwrap();
        assert_eq!(
            extract_marc!(latin "245a")(&record),
            vec![String::from("Kirin malgo kirin :")]
        );
    }

    #[test]
    fn extract_marc_macro_can_return_just_non_latin() {
        let record = Record::from_breaker(r#"=245 00 $6880-01 $a Kirin malgo kirin : $b 2023 Yangju Sirip Hoeam Saji Pangmulgwan t'ŭkpyŏl chŏnsi = Not giraffe but qilin : 2023 Hoeamsaji Museum of Yangju City spcial exhibition.
=880 00 $6245-01 $a 기린 말고 기린 : $b 2023 양주 시립 회암 사지 박물관 특별 전시 = Not giraffe but qilin : 2023 Hoeamsaji Museum of Yangju City spcial exhibition."#).unwrap();
        assert_eq!(
            extract_marc!(non_latin "245a")(&record),
            vec![String::from("기린 말고 기린 :")]
        );
    }
}
