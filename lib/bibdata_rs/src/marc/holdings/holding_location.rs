use std::collections::HashMap;

use marctk::{Field, Record};

use crate::{
    locations::HOLDING_LOCATIONS,
    marc::{alma_code_start_22, control_field::control_number::ControlNumber},
};

pub fn location_label(code: &str) -> Option<&str> {
    HOLDING_LOCATIONS.get(code).map(|location| location.label)
}

pub fn library_label(code: &str) -> Option<&str> {
    HOLDING_LOCATIONS
        .get(code)
        .map(|location| location.library.label)
}

pub fn mapped_codes_location_label(code: &str) -> HashMap<&str, &str> {
    let mut mapped = HashMap::new();
    if let Some(label) = location_label(code) {
        mapped.insert(code, label);
    }
    mapped
}

pub fn location_codes(record: &Record) -> Vec<String> {
    let mut codes = Vec::new();
    for field_852 in record.get_fields("852") {
        if !field_852.has_subfield("b") {
            continue;
        }

        let holding_id = field_852
            .first_subfield("8")
            .map(|sf| sf.content().to_string());

        let field_876 = holding_id.as_ref().and_then(|id| {
            let all_876 = record.get_fields("876");

            all_876
                .iter()
                .find(|field_876| {
                    field_876
                        .first_subfield("0")
                        .map(|sf| sf.content().to_string())
                        == Some(id.clone())
                })
                .cloned()
        });

        // Calculate permanent and current location codes
        let perm_code = match ControlNumber::from(record) {
            ControlNumber::Alma(_) => alma_permanent_location_code(&field_852),
            ControlNumber::SCSB(_) => partner_permanent_location_code(field_852),
            _ => None,
        };
        let curr_code = field_876.and_then(current_location_code);

        let location_code = match (curr_code, perm_code) {
            (Some(curr), Some(perm)) if curr == "RES_SHARE$IN_RS_REQ" => Some(perm),
            (Some(curr), Some(perm)) if curr != perm => Some(curr),
            (Some(curr), _) => Some(curr),
            (None, Some(perm)) => Some(perm),
            _ => None,
        };
        if let Some(c) = location_code {
            codes.push(c);
        }
    }
    codes
}

pub fn alma_permanent_location_code(field: &Field) -> Option<String> {
    match field.first_subfield("8") {
        // These are Princeton Alma records
        Some(alma_code) if alma_code_start_22(alma_code.content().to_string()) => {
            let b = field
                .first_subfield("b")
                .map(|subfield| subfield.content())
                .unwrap_or_default();
            let c = field
                .first_subfield("c")
                .map(|subfield| subfield.content())
                .unwrap_or_default();
            if c.is_empty() {
                Some(b.to_string())
            } else {
                Some(format!("{b}${c}"))
            }
        }
        // A record may have an 852 field without a subfield 8, but it is not a valid source of
        // information for the permanent location code
        _ => None,
    }
}

pub fn partner_permanent_location_code(field: &Field) -> Option<String> {
    field
        .first_subfield("0")
        .and(field.first_subfield("b"))
        .map(|subfield| subfield.content().to_string())
}

pub fn current_location_code(field: &Field) -> Option<String> {
    match (field.first_subfield("y"), field.first_subfield("z")) {
        (Some(y), Some(z)) => Some(format!("{}${}", y.content(), z.content())),
        _ => None,
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn it_can_get_the_location_label() {
        assert_eq!(location_label("scsbcul"), Some("Remote Storage"));
    }

    #[test]
    fn it_can_get_the_library_label() {
        assert_eq!(library_label("scsbcul"), Some("ReCAP"));
    }

    #[test]
    fn it_can_return_mapped_codes_to_location_labels() {
        let mapped_code = mapped_codes_location_label("firestone$pf");
        let mut expected = std::collections::HashMap::new();
        expected.insert(
            "firestone$pf",
            "Remote Storage (ReCAP): Firestone Library Use Only",
        );
        assert_eq!(mapped_code, expected);
    }

    #[test]
    fn it_does_not_include_location_codes_without_library() {
        let record = Record::from_breaker(
            r#"=001 9926233506421
=852 0\$bmarquand$cstacks$hND1053.4$i.K5 1934$822617214130006421
=852 0\$cpa$hND1053.4$i.K5 1934$822617214130006421
=852 0\$beastasian$cpl$hND1053.4$i.K5 1934$822966900120006421
=876 \\$022966900120006421$zpl$yeastasian"#,
        )
        .unwrap();
        assert!(
            !location_codes(&record).contains(&String::from("$pa")),
            "it does not include a partial location code $pa that has no library attached (no 852$b)"
        );
        assert_eq!(
            location_codes(&record),
            vec!["marquand$stacks", "eastasian$pl"]
        )
    }

    #[test]
    fn it_gets_location_codes_from_partner_record_with_852_subfield8() {
        let record = Record::from_breaker(
            r#"=001 SCSB-12345
=852 8\$cHD$hARG$i905$iAVE$8221940647990003941$010744464$bscsbhl"#,
        )
        .unwrap();
        assert_eq!(location_codes(&record), vec!["scsbhl"]);
    }

    #[test]
    fn it_ignores_location_codes_from_incorrect_852_for_alma() {
        let record = Record::from_breaker(
            r#"=001 9926233506421
=852 00$02950$bues$t1$hNA2541$i.M37"#,
        )
        .unwrap();
        eprintln!("THE CODES ARE: {:?}", location_codes(&record));
        assert!(location_codes(&record).is_empty());
    }
}
