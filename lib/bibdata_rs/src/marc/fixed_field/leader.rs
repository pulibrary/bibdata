use marctk::Record;

pub enum TypeOfRecord {
    LanguageMaterial,
    NotatedMusic,
    ManuscriptNotatedMusic,
    CartographicMaterial,
    ManuscriptCartographicMaterial,
    ProjectedMedium,
    NonmusicalSoundRecording,
    MusicalSoundRecording,
    TwoDimensionalNonProjectableGraphic,
    ComputerFile,
    Kit,
    MixedMaterials,
    ThreeDimensionalArtifactOrNaturallyOcurringObject,
    ManuscriptLanguageMaterial,
}

impl TryFrom<char> for TypeOfRecord {
    type Error = String;

    fn try_from(value: char) -> Result<Self, Self::Error> {
        match value {
            'a' => Ok(Self::LanguageMaterial),
            'c' => Ok(Self::NotatedMusic),
            'd' => Ok(Self::ManuscriptNotatedMusic),
            'e' => Ok(Self::CartographicMaterial),
            'f' => Ok(Self::ManuscriptCartographicMaterial),
            'g' => Ok(Self::ProjectedMedium),
            'i' => Ok(Self::NonmusicalSoundRecording),
            'j' => Ok(Self::MusicalSoundRecording),
            'k' => Ok(Self::TwoDimensionalNonProjectableGraphic),
            'm' => Ok(Self::ComputerFile),
            'o' => Ok(Self::Kit),
            'p' => Ok(Self::MixedMaterials),
            'r' => Ok(Self::ThreeDimensionalArtifactOrNaturallyOcurringObject),
            't' => Ok(Self::ManuscriptLanguageMaterial),
            _ => Err(format!("{} is not a valid type of record", value)),
        }
    }
}

impl TryFrom<&Record> for TypeOfRecord {
    type Error = String;
    fn try_from(value: &Record) -> Result<Self, Self::Error> {
        value
            .leader()
            .chars()
            .nth(6)
            .ok_or("No Type of Record at LDR/06")?
            .try_into()
    }
}

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

#[cfg(test)]
mod tests {
    use super::*;

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

    #[test]
    fn it_can_identify_manuscript_notated_music() {
        let manuscript_notated_music =
            Record::from_breaker("=LDR 02190cdm a2200385 i 4500").unwrap();
        assert!(matches!(
            TypeOfRecord::try_from(&manuscript_notated_music),
            Ok(TypeOfRecord::ManuscriptNotatedMusic)
        ));
    }
}
