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

#[derive(serde::Serialize)]
struct PortfolioFields {
    desc: String,
    display_format: String,
    end: String,
    notes: Vec<String>,
    source_id: String,
    start: String,
    title: String,
    url: String,
}

pub fn electronic_portfolio_s(record: &Record) -> Option<String> {
    let fields = active_fields(record).collect_vec();

    serde_json::to_string(&fields).ok()
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
                desc: field.first_subfield("k").unwrap().content().to_owned(),
                display_format: format(record),
                end: compute_date(record, field.clone(), EndDate),
                notes: field.get_subfields("i")
                    .iter().map(|s| s.content().to_owned())
                    .collect_vec(),
                source_id: source_id(record),
                start: compute_date(record, field.clone(), StartDate),
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

fn source_id(record: &Record) -> String {
    record.get_control_fields("001").first().unwrap().content().to_owned()
}

fn embargos(record: &Record) -> Vec<Field> {
    record.get_fields("954")
        .iter()
        .filter(|field| {
            let code = field.first_subfield("a").unwrap().content();
            code.starts_with("53") && code.ends_with("06421")
        })
        .map(|field| (*field).clone())
        .collect_vec()
}

fn dates(record: &Record) -> Vec<Field> {
    record.get_fields("953")
        .iter()
        .filter(|field| {
            let code = field.first_subfield("a").unwrap().content();
            code.starts_with("53") && code.ends_with("06421")
        })
        .map(|field| (*field).clone())
        .collect_vec()
}

fn embargo_to_embargo_length(embargo: Field) -> i16 {
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
        (StartDate, "&lt;=") => embargo_to_embargo_length(embargo).to_string(),
        (StartDate, "&lt;") => (embargo_to_embargo_length(embargo) + 1).to_string(),
        (StartDate, _) => date.first_subfield("b").unwrap().content().to_owned(),
        (EndDate, "&gt;=") => embargo_to_embargo_length(embargo).to_string(),
        (EndDate, "&lt;=" | "&lt;") => "latest".to_owned(),
        (EndDate, "&gt;") => (embargo_to_embargo_length(embargo) - 1).to_string(),
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
    fn it_can_build_electronic_portfolio_s() {
        let record =
            Record::from_breaker("=LDR 02646nas a2200673 i 4500
=001 99122306151806421
=951 \\\\$aAvailable$kAvailable from 1869 volume: 1 issue: 1.$w2021-07-13 12:24:58$853443322630006421$xhttps://example.com$iSome Note
=953 \\\\$a53443322630006421$b1990
=954 \\\\$a53443322630006421
=951 \\\\$aAvailable$kAvailable from 01/04/1990. Most recent 1 year(s) not available.$nProQuest Central$853443322640006421$xhttps://na07.alma.exlibrisgroup.com/view/uresolver/01PRI_INST/openurl?u.ignore_date_coverage=true&amp;portfolio_pid=53443322640006421&amp;Force_direct=true
=953 \\\\$a53443322640006421$b1990
=954 \\\\$a53443322640006421")
                .unwrap();
        assert_eq!(
            electronic_portfolio_s(&record),
            Some("[{\"desc\":\"Available from 1869 volume: 1 issue: 1.\",\"display_format\":\"Journal\",\"end\":\"latest\",\"notes\":[\"Some Note\"],\"source_id\":\"99122306151806421\",\"start\":\"1990\",\"title\":\"Online Content\",\"url\":\"https://example.com\"},{\"desc\":\"Available from 01/04/1990. Most recent 1 year(s) not available.\",\"display_format\":\"Journal\",\"end\":\"latest\",\"notes\":[],\"source_id\":\"99122306151806421\",\"start\":\"1990\",\"title\":\"ProQuest Central\",\"url\":\"https://na07.alma.exlibrisgroup.com/view/uresolver/01PRI_INST/openurl?u.ignore_date_coverage=true&amp;portfolio_pid=53443322640006421&amp;Force_direct=true\"}]".to_owned())
        )
    }

    #[test]
    fn it_gets_title_from_record() {
        let mut field = Field::new("951").ok().unwrap();
        let _ = field.add_subfield("n", "ProQuest Central");
        assert_eq!(title(&field), "ProQuest Central");

        let field_no_title = Field::new("951").ok().unwrap();
        assert_eq!(title(&field_no_title), "Online Content")
    }

    #[test]
    fn it_get_display_format_from_record() {
        let record =
            Record::from_breaker("=LDR 02646nas a2200673 i 4500")
                .unwrap();
        assert_eq!(format(&record), "Journal");
    }

    #[test]
    fn it_get_source_id_from_record() {
        let record =
            Record::from_breaker("=001 99122306151806421")
                .unwrap();
        assert_eq!(source_id(&record), "99122306151806421");
    }

    #[test]
    fn it_gets_embargos_from_954() {
        let record =
            Record::from_breaker("=001 99122306151806421
=951 \\$aAvailable$kAvailable from 1869 volume: 1 issue: 1.$w2021-07-13 12:24:58$853443322630006421
=954 \\\\$a53443322630006421")
                .unwrap();
        let mut field = Field::new("954").ok().unwrap();
            let _ = field.set_ind1(" ");
            let _ = field.set_ind2(" ");
            let _ = field.add_subfield("a", "53443322630006421");
        assert_eq!(
            embargos(&record),
            vec![field]
        )
    }

    #[test]
    fn it_gets_dates_from_953() {
        let record =
            Record::from_breaker("=001 99122306151806421
=953 \\\\$a53443322630006421$b1990")
                .unwrap();
        let mut field = Field::new("953").ok().unwrap();
            let _ = field.set_ind1(" ");
            let _ = field.set_ind2(" ");
            let _ = field.add_subfield("a", "53443322630006421");
            let _ = field.add_subfield("b", "1990");
        assert_eq!(
            dates(&record),
            vec![field]
        )
    }

    #[test]
    fn it_gets_data_from_951() {
        let record =
            Record::from_breaker("=001 99122306151806421
=951 \\\\$aAvailable$kAvailable from 1869 volume: 1 issue: 1.$w2021-07-13 12:24:58$853443322630006421
=954 \\\\$a53443322630006421")
                .unwrap();
        let mut field = Field::new("951").ok().unwrap();
        let _ = field.set_ind1(" ");
        let _ = field.set_ind2(" ");
        let _ = field.add_subfield("a", "Available");
        let _ = field.add_subfield("k", "Available from 1869 volume: 1 issue: 1.");
        let _ = field.add_subfield("w", "2021-07-13 12:24:58");
        let _ = field.add_subfield("8", "53443322630006421");

        assert_eq!(
            record.extract_field_values_by(
                |f| f.tag() == "951",
                |r| Some(r)
            ).collect_vec().first(),
            Some(&&field)
        )
    }

    #[test]
    fn it_converts_embargo_length_to_date() {
        let mut field = Field::new("954").ok().unwrap();
        let _ = field.add_subfield("c", "2015");
        assert_eq!(embargo_to_embargo_length(field), 11);
    }

    #[test]
    fn it_computes_start_and_end_dates_correctly() {
        let record_lt_eq =
            Record::from_breaker("=953 \\\\$a53443322630006421$b1990
=954 \\\\$a53443322630006421$b&lt;=$c1")
                .unwrap();
        let record_lt =
            Record::from_breaker("=953 \\\\$a53443322630006421$b1990
=954 \\\\$a53443322630006421$b&lt;$c1")
                .unwrap();
        let record_gt_eq =
            Record::from_breaker("=953 \\\\$a53443322630006421$b1990
=954 \\\\$a53443322630006421$b&gt;=$c1")
                .unwrap();
        let record_gt =
            Record::from_breaker("=953 \\\\$a53443322630006421$b1990
=954 \\\\$a53443322630006421$b&gt;$c1")
                .unwrap();
            let record_eq_gt =
            Record::from_breaker("=953 \\\\$a53443322630006421$b1990$c2015
=954 \\\\$a53443322630006421$b=&gt;$c1")
                .unwrap();
            let record_no_date =
            Record::from_breaker("=953 \\\\$a53443322630006421$b1990
=954 \\\\$a53443322630006421$b&=gt;")
                .unwrap();
        let mut field = Field::new("951").ok().unwrap();
        let _ = field.add_subfield("8", "53443322630006421");
        assert_eq!(
            compute_date(&record_lt_eq, field.clone(), StartDate),
            "2025"
        );
        assert_eq!(
            compute_date(&record_lt, field.clone(), StartDate),
            "2026"
        );
        assert_eq!(
            compute_date(&record_gt, field.clone(), StartDate),
            "1990"
        );
        assert_eq!(
            compute_date(&record_gt_eq, field.clone(), EndDate),
            "2025"
        );
        assert_eq!(
            compute_date(&record_lt_eq, field.clone(), EndDate),
            "latest"
        );
        assert_eq!(
            compute_date(&record_lt, field.clone(), EndDate),
            "latest"
        );
        assert_eq!(
            compute_date(&record_gt, field.clone(), EndDate),
            "2024"
        );
        assert_eq!(
            compute_date(&record_eq_gt, field.clone(), EndDate),
            "2015"
        );
        assert_eq!(
            compute_date(&record_no_date, field.clone(), EndDate),
            "latest"
        );
    }
}
