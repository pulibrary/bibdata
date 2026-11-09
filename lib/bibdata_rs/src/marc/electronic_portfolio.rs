use itertools::Itertools;
use jiff::Zoned;
use marctk::{Field, Record};

use DateType::*;

use crate::marc::{
    alma::AlmaElectronicPortfolio,
    extract_values::ExtractValues,
    record_facet_mapping::formats,
    utils::display_format::display_format
};

enum DateType {
    StartDate,
    EndDate,
}
struct PortfolioFields {
    description: String,
    end_date: String,
    notes: Vec<String>,
    start_date: String,
    title: String,
    url: String,
}

pub fn electronic_portfolio_s(record: &Record) -> Option<String> {
    let fields = active_fields(record);

    Some(fields.map(|d| d.title).join(""))


}

fn active_fields(record: &Record) -> impl Iterator<Item = PortfolioFields> {
    record
        .extract_field_values_by(
            |field| {
                matches!(
                    AlmaElectronicPortfolio::try_from(field),
                    Ok(AlmaElectronicPortfolio::Active)
                )
            },
            |field| Some(PortfolioFields {
                description: field.first_subfield("k").unwrap().content().to_owned(),
                end_date: compute_date(record, field.clone(), EndDate),
                notes: field.get_subfields("i")
                    .iter().map(|s| s.content().to_owned())
                    .collect_vec(),
                start_date: compute_date(record, field.clone(), StartDate),
                title: title(field),
                url: field.first_subfield("x").unwrap().content().to_owned()
            })
        )
}

fn title(field: &Field) -> String {
    match field.first_subfield("n") {
        Some(t) => t.content().to_owned(),
        None => "Online Content".to_owned(),
    }
}

fn format(record: &Record) -> String {
    display_format(formats(record))
}

fn source_id(record: &Record) -> &str {
    record.get_control_fields("001").first().unwrap().content()
}

fn embargos(record: &Record) -> Vec<Field> {
    record.get_fields("954")
        .iter()
        .filter(|field| {
            let code = field.first_subfield("a").unwrap().content();
            code.starts_with("53") && code.ends_with("06421")
        })
        .map(|field| field.clone().clone())
        .collect_vec()
        
}

fn dates(record: &Record) -> Vec<Field> {
    record.get_fields("953")
        .iter()
        .filter(|field| {
            let code = field.first_subfield("a").unwrap().content();
            code.starts_with("53") && code.ends_with("06421")
        })
        .map(|field| field.clone().clone())
        .collect_vec()
}

fn embargo_to_year(embargo: Field) -> i16 {
    let year = Zoned::now().year();
    let embargo_length: i16 = embargo.first_subfield("c").unwrap().content().parse().unwrap();
    year - embargo_length
}

fn compute_date(record: &Record, field: Field, date_type: DateType) -> String {
    let code = field.first_subfield("8").unwrap().content();
    let embargo = embargos(record)
        .into_iter()
        .find(|e| e.first_subfield("a").unwrap().content() == code).unwrap();
    let date = dates(record)
        .into_iter()
        .find(|d| d.first_subfield("a").unwrap().content() == code).unwrap();
    let indicator = match embargo.first_subfield("b") {
        Some(s) => s.content().to_owned(),
        None => "No Indicator".to_owned()
    };

    match (date_type, indicator.as_str()) {
        (StartDate, "<=") => embargo_to_year(embargo).to_string(),
        (StartDate, "<") => (embargo_to_year(embargo) + 1).to_string(),
        (StartDate, _) => date.first_subfield("b").unwrap().content().to_owned(),
        (EndDate, ">=") => embargo_to_year(embargo).to_string(),
        (EndDate, "<=" | "<") => "latest".to_owned(),
        (EndDate, ">") => (embargo_to_year(embargo) - 1).to_string(),
        (EndDate, _) => match date.first_subfield("c") {
            Some(f) => f.content().to_owned(),
            None => "latest".to_owned()
        }

    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn it_gets_cataloged_date_from_active_951_portfolio() {
        let record =
            Record::from_breaker("=951 \\$aAvailable$8531026240820006421$w2021-07-13 12:24:58")
                .unwrap();
        assert_eq!(
            electronic_portfolio_s(&record),
            Some("2021-07-13T12:24:58Z".to_owned())
        )
    }
}
