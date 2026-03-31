use crate::marc::extract_values::ExtractValues;
use itertools::Itertools;
use marctk::Record;

pub fn latin_script_title(record: &Record) -> Option<String> {
    record
        .extract_field_values_by(
            |field| field.tag() == "245",
            |field| {
                Some(
                    field
                        .subfields()
                        .iter()
                        .filter(|subfield| ["abchknps"].contains(&subfield.code()))
                        .map(|subfield| subfield.content())
                        .join(" "),
                )
            },
        )
        .next()
}
