use marctk::Record;

// This module is for the 040 of a MARC bibliographic record: Cataloging Source

pub enum DescriptionConvention {
    Appm,
    Dacs,
    Rda,
    OtherDescriptionConvention,
}

impl DescriptionConvention {
    pub fn is_archival(&self) -> bool {
        matches!(
            self,
            DescriptionConvention::Appm | DescriptionConvention::Dacs
        )
    }
}

impl From<&str> for DescriptionConvention {
    fn from(value: &str) -> Self {
        match value {
            "appm" => DescriptionConvention::Appm,
            "dacs" => DescriptionConvention::Dacs,
            "rda" => DescriptionConvention::Rda,
            _ => DescriptionConvention::OtherDescriptionConvention,
        }
    }
}

pub fn description_conventions(record: &Record) -> Vec<DescriptionConvention> {
    record
        .extract_values("040e")
        .iter()
        .map(|code| DescriptionConvention::from(code.trim()))
        .collect()
}

pub fn uses_archival_description(record: &Record) -> bool {
    let description_conventions = description_conventions(record);
    description_conventions.is_empty()
        || description_conventions
            .iter()
            .all(|convention| convention.is_archival())
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn it_categorizes_record_with_no_040_as_archival_description() {
        let record = Record::from_breaker("").unwrap();
        assert!(uses_archival_description(&record));
    }

    #[test]
    fn it_categorizes_record_with_no_040e_as_archival_description() {
        let record = Record::from_breaker("=040 \\ $aCaOTY$beng").unwrap();
        assert!(uses_archival_description(&record));
    }

    #[test]
    fn it_does_not_categorize_record_with_040e_rda_as_archival_description() {
        let record = Record::from_breaker("=040 \\ $aCaOTY$beng$erda").unwrap();
        assert!(!uses_archival_description(&record));
    }

    #[test]
    fn it_categorizes_record_with_040e_dacs_as_archival_description() {
        let record = Record::from_breaker("=040 \\ $aCaOTY$beng$edacs").unwrap();
        assert!(uses_archival_description(&record));
    }

    #[test]
    fn it_categorizes_record_with_040e_appm_as_archival_description() {
        let record = Record::from_breaker("=040 \\ $aCaOTY$beng$eappm").unwrap();
        assert!(uses_archival_description(&record));
    }
}
