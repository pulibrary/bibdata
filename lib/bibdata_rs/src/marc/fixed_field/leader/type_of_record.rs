use marctk::Record;

/// The Type of Record is taken from LDR/06 of a MARC record
pub enum TypeOfRecord {
    /// LDR/06 a
    LanguageMaterial,
    /// LDR/06 c
    NotatedMusic,
    /// LDR/06 d
    ManuscriptNotatedMusic,
    /// LDR/06 e
    CartographicMaterial,
    /// LDR/06 f
    ManuscriptCartographicMaterial,
    /// LDR/06 g
    ProjectedMedium,
    /// LDR/06 i
    NonmusicalSoundRecording,
    /// LDR/06 j
    MusicalSoundRecording,
    /// LDR/06 k
    TwoDimensionalNonProjectableGraphic,
    /// LDR/06 m
    ComputerFile,
    /// LDR/06 o
    Kit,
    /// LDR/06 p
    MixedMaterials,
    /// LDR/06 r
    ThreeDimensionalArtifactOrNaturallyOcurringObject,
    /// LDR/06 t
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

#[cfg(test)]
mod tests {
    use super::*;

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
