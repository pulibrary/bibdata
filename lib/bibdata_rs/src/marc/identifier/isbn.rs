use crate::marc::variable_length_field::VariableLengthField;
use library_stdnums::{isbn::ISBN, traits::Normalize};
use marctk::{Field, Record};
use std::ops::Deref;

struct Field020<'a>(&'a Field);

impl<'a> Field020<'a> {
    pub fn number(&'a self) -> Option<&'a str> {
        self.get("a")
    }

    pub fn qualifying_information(&'a self) -> Vec<&'a str> {
        self.subfields()
            .iter()
            .filter(|subfield| subfield.code() == "q")
            .map(|subfield| subfield.content())
            .collect()
    }
}

impl Deref for Field020<'_> {
    type Target = Field;

    fn deref(&self) -> &Self::Target {
        self.0
    }
}

pub fn normalized_isbns_for_all_versions(record: &Record) -> impl Iterator<Item = String> {
    record
        .extract_values("020az:776z")
        .into_iter()
        .filter_map(|value| ISBN::new(value).normalize())
}

pub fn isbn_display(record: &Record) -> impl Iterator<Item = String> {
    record
        .fields()
        .iter()
        .filter(|field| field.tag() == "020")
        .map(Field020)
        .filter_map(
            |field| match (field.number(), field.qualifying_information()) {
                (Some(number), qualifying_information) if qualifying_information.is_empty() => {
                    Some(number.to_string())
                }
                (Some(number), qualifying_information) => {
                    Some(format!("{number} ({})", qualifying_information.join(" : ")))
                }
                _ => None,
            },
        )
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn it_formats_the_isbn_for_display() {
        let record = Record::from_breaker(r#"=020 \\$a0-8130-6731-6$qPaperback"#).unwrap();
        let mut isbns = isbn_display(&record);
        assert_eq!(
            isbns.next(),
            Some(String::from("0-8130-6731-6 (Paperback)"))
        );
        assert_eq!(isbns.next(), None);
    }
}
