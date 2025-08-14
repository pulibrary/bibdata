use marctk::Record;

pub enum BibliographicLevel {
    MonographicComponentPart,
    SerialComponentPart,
    Collection,
    Subunit,
    IntegratingResource,
    MonographItem,
    Serial,
}

impl BibliographicLevel {
    pub fn is_serial(&self) -> bool {
        matches!(self, Self::SerialComponentPart | Self::Serial)
    }

    pub fn is_monograph(&self) -> bool {
        matches!(
            self,
            Self::MonographicComponentPart
                | Self::SerialComponentPart
                | Self::Collection
                | Self::Subunit
                | Self::MonographItem
        )
    }
}

impl TryFrom<char> for BibliographicLevel {
    type Error = String;

    fn try_from(value: char) -> Result<Self, Self::Error> {
        match value {
            'a' => Ok(Self::MonographicComponentPart),
            'b' => Ok(Self::SerialComponentPart),
            'c' => Ok(Self::Collection),
            'd' => Ok(Self::Subunit),
            'i' => Ok(Self::IntegratingResource),
            'm' => Ok(Self::MonographItem),
            's' => Ok(Self::Serial),
            _ => Err(format!("{} is not a valid bibliographic level", value)),
        }
    }
}

impl TryFrom<&Record> for BibliographicLevel {
    type Error = String;
    fn try_from(value: &Record) -> Result<Self, Self::Error> {
        value
            .leader()
            .chars()
            .nth(7)
            .ok_or("No Bibliographic level at LDR/07")?
            .try_into()
    }
}

pub fn is_monograph(record: &Record) -> bool {
    match BibliographicLevel::try_from(record) {
        Ok(level) => level.is_monograph(),
        _ => false,
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use marctk::Record;

    #[test]
    fn it_can_identify_a_serials_record() {
        let serial_record = Record::from_breaker("=LDR 01644cas a2200397 a 4500").unwrap();
        assert!(BibliographicLevel::try_from(&serial_record)
            .unwrap()
            .is_serial());

        let monograph_record = Record::from_breaker("=LDR 04137cam a2200853Ii 4500").unwrap();
        assert!(!BibliographicLevel::try_from(&monograph_record)
            .unwrap()
            .is_serial());
    }
}
