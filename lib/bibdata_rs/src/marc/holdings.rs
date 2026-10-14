pub mod holding_location;
pub mod library;
pub mod partner;
use crate::marc::string_normalize::maybe_not_empty;
use itertools::Itertools;
use marctk::Field;

pub struct Field852<'a>(&'a Field);
impl<'a> Field852<'a> {
    pub fn get(&self, subfield_code: &str) -> Option<&'a str> {
        self.0
            .first_subfield(subfield_code)
            .map(|subfield| subfield.content())
    }

    pub fn call_number(&self) -> Option<String> {
        let call_number = self
            .0
            .subfields()
            .iter()
            .filter(|subfield| ["h", "i", "k", "j"].contains(&subfield.code()))
            .map(|subfield| subfield.content().to_string())
            .filter(|s| !s.is_empty())
            .join(" ");
        maybe_not_empty(call_number)
    }
}

pub struct Field876<'a>(&'a Field);
impl<'a> Field876<'a> {
    pub fn get(&self, subfield_code: &str) -> Option<&'a str> {
        self.0
            .first_subfield(subfield_code)
            .map(|subfield| subfield.content())
    }
}

pub trait Holding {}
pub trait Item {}

// Get the $a and $z from an 866, 867, or 868 field
fn textual_holdings(field: &Field) -> Option<String> {
    let mut text = field
        .first_subfield("a")
        .into_iter()
        .map(|sf| sf.content())
        .chain(field.first_subfield("z").into_iter().map(|sf| sf.content()));
    maybe_not_empty(text.join(" "))
}
