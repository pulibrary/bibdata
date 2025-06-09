use marctk::Record;

#[derive(Debug, PartialEq)]
pub enum LiteraryForm {
    NotFiction,
    Fiction,
    Dramas,
    Essays,
    Novels,
    HumorSatireEtc,
    Letters,
    ShortStories,
    MixedForms,
    Poetry,
    Speeches,
}

impl LiteraryForm {
    pub fn is_literature(&self) -> bool {
        matches!(
            self,
            Self::Fiction
                | Self::Dramas
                | Self::Essays
                | Self::Novels
                | Self::ShortStories
                | Self::Poetry
        )
    }
}

impl TryFrom<char> for LiteraryForm {
    type Error = String;

    fn try_from(value: char) -> Result<Self, Self::Error> {
        match value {
            '0' => Ok(Self::NotFiction),
            '1' => Ok(Self::Fiction),
            'd' => Ok(Self::Dramas),
            'e' => Ok(Self::Essays),
            'f' => Ok(Self::Novels),
            'h' => Ok(Self::HumorSatireEtc),
            'i' => Ok(Self::Letters),
            'j' => Ok(Self::ShortStories),
            'm' => Ok(Self::MixedForms),
            'p' => Ok(Self::Poetry),
            's' => Ok(Self::Speeches),
            _ => Err(format!("No such literary form code {}", value)),
        }
    }
}
pub fn literary_forms(record: &Record) -> Vec<LiteraryForm> {
    record
        .get_control_fields("008")
        .iter()
        .filter_map(|field| match field.content().chars().nth(33) {
            Some(c) => c.try_into().ok(),
            None => None,
        })
        .collect()
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn it_tries_to_convert_chars_into_literary_forms() {
        assert_eq!('h'.try_into(), Ok(LiteraryForm::HumorSatireEtc));

        let empty_literary_form: Result<LiteraryForm, String> = ' '.try_into();
        assert!(empty_literary_form.is_err());
    }

    #[test]
    fn it_can_identify_whether_a_form_is_literature() {
        assert!(LiteraryForm::Fiction.is_literature());
        assert!(LiteraryForm::Novels.is_literature());

        assert!(!LiteraryForm::NotFiction.is_literature());
        assert!(!LiteraryForm::Letters.is_literature());
    }
}
