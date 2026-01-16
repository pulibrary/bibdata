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

fn field_extractor_for_record(
    record: &Record,
) -> fn(&Record) -> Box<dyn Iterator<Item = &Field> + '_> {
    if is_scsb(record) {
        scsb_call_number_fields
    } else {
        alma_call_number_fields
    }
}

fn call_number_labels(
    record: &Record,
    field_extractor: fn(&Record) -> Box<dyn Iterator<Item = &Field> + '_>,
    field_labeler: fn(&Field) -> Option<String>,
) -> Vec<String> {
    field_extractor(record).filter_map(field_labeler).collect()
}

fn scsb_call_number_fields(record: &Record) -> Box<dyn Iterator<Item = &Field> + '_> {
    Box::new(record.get_fields("852").into_iter().filter(|field| {
        field
            .first_subfield("b")
            .is_some_and(|subfield_b| subfield_b.content().starts_with("scsb"))
    }))
}

fn alma_call_number_fields(record: &Record) -> Box<dyn Iterator<Item = &Field> + '_> {
    Box::new(record.get_fields("852").into_iter().filter(|field| {
        field.first_subfield("8").is_some_and(|subfield_8| {
            subfield_8.content().starts_with("22") && subfield_8.content().ends_with("06421")
        })
    }))
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

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn it_creates_call_number_labels() {
        let alma_record = Record::from_breaker(
            r"=852 0\ $firestone$cnec$hBP166.38$i.A284 2003$822583221030006421",
        )
        .unwrap();
        let scsb_record = Record::from_breaker(
            r#"=001 SCSB-123
=852 00 $0441372$hQ4$i.C4222a$bscsbcul"#,
        )
        .unwrap();
        assert_eq!(
            call_number_labels_for_display(&alma_record),
            ["BP166.38 .A284 2003"]
        );
        assert_eq!(
            call_number_labels_for_browse(&alma_record),
            ["BP166.38 .A284 2003"]
        );
        assert_eq!(call_number_labels_for_display(&scsb_record), ["Q4 .C4222a"]);
        assert_eq!(call_number_labels_for_browse(&scsb_record), ["Q4 .C4222a"]);
    }
}
