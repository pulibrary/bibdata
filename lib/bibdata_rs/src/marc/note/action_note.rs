// This module is responsible for processing Action notes
// See https://www.loc.gov/marc/bibliographic/bd583.html

use std::iter;

use itertools::Itertools;
use marctk::{Field, Record};
use serde::Serialize;

use crate::marc::{
    control_field::system_control_number::is_princeton_finding_aid, extract_values::ExtractValues,
    scsb::is_scsb, string_normalize::upcase_first,
    variable_length_field::latin_or_non_latin_tag_eq,
};

struct Field583<'a>(&'a Field);

impl<'a> Field583<'a> {
    pub fn action(&self) -> Option<&'a str> {
        self.get("a")
    }

    pub fn action_interval(&self) -> Option<&'a str> {
        self.get("d")
    }

    pub fn authorizations(&self) -> Vec<&'a str> {
        self.0
            .subfields()
            .iter()
            .filter(|subfield| subfield.code() == "f")
            .map(|subfield| subfield.content())
            .collect()
    }

    pub fn has_field_link(&self) -> bool {
        self.0
            .subfields()
            .iter()
            .any(|subfield| subfield.code() == "8")
    }

    pub fn institution(&self) -> Option<&'a str> {
        self.get("5")
    }

    pub fn is_public(&self) -> bool {
        self.0.ind1() == "1"
    }

    pub fn materials_specified(&self) -> Option<&'a str> {
        self.get("3")
    }

    pub fn uri(&self) -> Option<&'a str> {
        self.get("u")
    }

    fn get(&self, code: &str) -> Option<&'a str> {
        self.0
            .first_subfield(code)
            .map(|subfield| subfield.content())
    }
}

#[derive(Debug, PartialEq, Serialize)]
pub struct ActionNote<'a> {
    description: Option<String>,
    uri: Option<&'a str>,
}

enum ActionNoteError {
    NoteIsPrivate,
}

impl<'a> TryFrom<Field583<'a>> for ActionNote<'a> {
    type Error = ActionNoteError;

    fn try_from(field: Field583<'a>) -> Result<Self, Self::Error> {
        if !field.is_public() {
            return Err(ActionNoteError::NoteIsPrivate);
        };
        let description_string = [
            field
                .materials_specified()
                .map(|materials| format!("{materials}:")),
            field
                .action()
                .map(|action| upcase_first(action).to_string()),
            field.action_interval().map(ToString::to_string),
            authorizations_as_phrase(&field.authorizations()),
            field
                .institution()
                .map(|institution| format!("({institution})")),
        ]
        .iter()
        .flatten()
        .join(" ");
        let description = if description_string.is_empty() {
            None
        } else {
            Some(description_string)
        };
        Ok(ActionNote {
            description,
            uri: field.uri().map(|uri| uri.trim()),
        })
    }
}

pub fn action_notes<'a>(record: &'a Record) -> impl Iterator<Item = ActionNote<'a>> {
    record.extract_field_values_by(latin_or_non_latin_tag_eq(&["583"]), |field| {
        let field = Field583(field);
        if field.has_field_link() || is_scsb(record) || is_princeton_finding_aid(record) {
            ActionNote::try_from(field).ok()
        } else {
            None
        }
    })
}

fn authorizations_as_phrase(authorizations: &Vec<&str>) -> Option<String> {
    if authorizations.is_empty() {
        None
    } else {
        Some(iter::once(&"—").chain(authorizations).join(" "))
    }
}
