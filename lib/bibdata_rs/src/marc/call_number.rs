use crate::marc::scsb::is_scsb;
use itertools::Itertools;
use marctk::{Field, Record};

pub fn call_number_labels_for_display(record: &Record) -> Vec<String> {
    call_number_labels(
        record,
        field_extractor_for_record(record),
        display_field_labeler,
    )
}

pub fn call_number_labels_for_browse(record: &Record) -> Vec<String> {
    call_number_labels(
        record,
        field_extractor_for_record(record),
        browse_field_labeler,
    )
}

fn field_extractor_for_record(record: &Record) -> fn(&Record) -> Vec<&Field> {
    if is_scsb(record) {
        scsb_call_number_fields
    } else {
        alma_call_number_fields
    }
}

fn call_number_labels(
    record: &Record,
    field_extractor: fn(&Record) -> Vec<&Field>,
    field_labeler: fn(&Field) -> Option<String>,
) -> Vec<String> {
    field_extractor(record)
        .into_iter()
        .filter_map(field_labeler)
        .collect()
}

fn scsb_call_number_fields(record: &Record) -> Vec<&Field> {
    record
        .get_fields("852")
        .into_iter()
        .filter(|field| {
            field
                .first_subfield("b")
                .is_some_and(|subfield_b| subfield_b.content().starts_with("scsb"))
        })
        .collect()
}

fn alma_call_number_fields(record: &Record) -> Vec<&Field> {
    record
        .get_fields("852")
        .into_iter()
        .filter(|field| {
            field.first_subfield("8").is_some_and(|subfield_8| {
                subfield_8.content().starts_with("22") && subfield_8.content().ends_with("06421")
            })
        })
        .collect()
}

fn display_field_labeler(field: &Field) -> Option<String> {
    let label = [
        field.first_subfield("k"),
        field.first_subfield("h"),
        field.first_subfield("i"),
    ]
    .iter()
    .flatten()
    .map(|subfield| subfield.content().trim())
    .filter(|part| !part.is_empty())
    .join(" ");
    if label.is_empty() {
        None
    } else {
        Some(label.to_owned())
    }
}

fn browse_field_labeler(field: &Field) -> Option<String> {
    let label = [
        field.first_subfield("h"),
        field.first_subfield("i"),
        field.first_subfield("k"),
    ]
    .iter()
    .flatten()
    .map(|subfield| subfield.content().trim())
    .filter(|part| !part.is_empty())
    .join(" ");
    if label.is_empty() {
        None
    } else {
        Some(label.to_owned())
    }
}
