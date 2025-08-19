use marctk::Record;
use std::str::FromStr;

use super::{collection_group::collection_groups, is_scsb};

#[derive(Debug, PartialEq)]
pub enum RecapPartner {
    ColumbiaUniversityLibrary,
    HarvardLibrary,
    NewYorkPublicLibrary,
}

impl RecapPartner {
    fn display_code(&self) -> char {
        match self {
            Self::ColumbiaUniversityLibrary => 'C',
            Self::HarvardLibrary => 'H',
            Self::NewYorkPublicLibrary => 'N',
        }
    }
}

#[derive(Debug, PartialEq)]
pub struct NoSuchRecapPartner;

impl FromStr for RecapPartner {
    type Err = NoSuchRecapPartner;

    fn from_str(s: &str) -> Result<Self, Self::Err> {
        if s.trim() == "scsbcul" {
            Ok(Self::ColumbiaUniversityLibrary)
        } else if s.trim() == "scsbhl" {
            Ok(Self::HarvardLibrary)
        } else if s.trim() == "scsbnypl" {
            Ok(Self::NewYorkPublicLibrary)
        } else {
            Err(NoSuchRecapPartner)
        }
    }
}

impl TryFrom<&Record> for RecapPartner {
    type Error = NoSuchRecapPartner;

    fn try_from(record: &Record) -> Result<Self, Self::Error> {
        if !is_scsb(record) || record.get_field_values("852", "0").is_empty() {
            return Err(NoSuchRecapPartner);
        }
        match record.get_field_values("852", "b").first() {
            Some(partner_code) => RecapPartner::from_str(partner_code),
            None => Err(NoSuchRecapPartner),
        }
    }
}

pub fn recap_partner_notes(record: &Record) -> Vec<String> {
    if !is_scsb(record) {
        return vec![];
    }
    let record_partner = RecapPartner::try_from(record);
    match record_partner {
        Ok(partner) => collection_groups(record)
            .iter()
            .map(|group| format!("{} - {}", partner.display_code(), group.code()))
            .collect(),
        Err(_) => vec![],
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn it_can_identify_nypl() {
        let record = Record::from_breaker(
            r#"=001 SCSB-8157262
=852 \\ $hJSM 95-217$09887434$bscsbnypl"#,
        )
        .unwrap();
        assert_eq!(
            RecapPartner::try_from(&record),
            Ok(RecapPartner::NewYorkPublicLibrary)
        );
    }

    mod recap_partner_notes {
        use super::*;
        #[test]
        fn it_can_create_a_columbia_open_note() {
            let record = Record::from_breaker(
                r#"=001 SCSB-9336516
=852 \\ $hAB Aj11$09760430$bscsbcul
=876 \\ $09760430$32006:June-Dec.$a15469769$hIn Library Use$jAvailable$pAR01836099$t1$xOpen$zAR$lRECAP"#,
            )
            .unwrap();
            assert_eq!(recap_partner_notes(&record), vec!["C - O".to_owned()]);
        }

        #[test]
        fn it_does_not_create_a_note_if_852_has_no_subfield_zero() {
            let record = Record::from_breaker(
                r#"=001 SCSB-9336516
=852 \\ $hAB Aj11$bscsbcul
=876 \\ $09760430$32006:June-Dec.$a15469769$hIn Library Use$jAvailable$pAR01836099$t1$xOpen$zAR$lRECAP"#,
            )
            .unwrap();
            assert!(recap_partner_notes(&record).is_empty());
        }
    }
}
