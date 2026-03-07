use marctk::{Field, Record};

use crate::{marc::trim_punctuation, solr::AuthorRoles};

impl From<&Record> for AuthorRoles {
    fn from(record: &Record) -> Self {
        let primary_author = record
            .extract_values("100a")
            .first()
            .map(|name| trim_punctuation(name));
        let mut secondary_authors: Vec<String> = Default::default();
        let mut compilers: Vec<String> = Default::default();
        let mut editors: Vec<String> = Default::default();
        let mut translators: Vec<String> = Default::default();
        let other_author_fields = record.fields().iter().filter(|field| {
            ["110", "111", "700", "710", "711"].contains(&field.tag()) && field.has_subfield("a")
        });
        for field in other_author_fields {
            match (ContributorType::from(field), field.first_subfield("a")) {
                (ContributorType::Compiler, Some(contributor_subfield)) => {
                    compilers.push(trim_punctuation(contributor_subfield.content()));
                }
                (ContributorType::Editor, Some(contributor_subfield)) => {
                    editors.push(trim_punctuation(contributor_subfield.content()));
                }
                (ContributorType::Translator, Some(contributor_subfield)) => {
                    translators.push(trim_punctuation(contributor_subfield.content()));
                }
                (_, Some(contributor_subfield)) => {
                    secondary_authors.push(trim_punctuation(contributor_subfield.content()));
                }
                _ => {}
            }
        }
        Self {
            primary_author,
            secondary_authors,
            compilers,
            editors,
            translators,
        }
    }
}

enum ContributorType {
    Compiler,
    Editor,
    Translator,
    Other,
}

impl From<&Field> for ContributorType {
    fn from(field: &Field) -> Self {
        let relator = find_potential_relator(field, "4").or(find_potential_relator(field, "e"));
        match relator.as_deref() {
            Some("COM") => Self::Compiler,
            Some("COMPILER") => Self::Compiler,
            Some("EDT") => Self::Editor,
            Some("EDITOR") => Self::Editor,
            Some("TRL") => Self::Translator,
            Some("TRANSLATOR") => Self::Translator,
            _ => Self::Other,
        }
    }
}

fn find_potential_relator(field: &Field, subfield: &str) -> Option<String> {
    field
        .first_subfield(subfield)
        .map(|subfield| clean_potential_relator(subfield.content()))
}

fn clean_potential_relator(raw: &str) -> String {
    raw.chars()
        .filter_map(|c| {
            if c.is_ascii_alphabetic() {
                Some(c.to_ascii_uppercase())
            } else {
                None
            }
        })
        .collect()
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn it_can_find_primary_author_from_marc_record() {
        let record = Record::from_breaker("=100 \\$aPrimary").unwrap();
        assert_eq!(
            AuthorRoles::from(&record),
            AuthorRoles {
                primary_author: Some("Primary".to_owned()),
                ..Default::default()
            }
        )
    }

    #[test]
    fn it_trims_spaces_and_punctuation_from_primary_author() {
        let record = Record::from_breaker("=100 \\$a Primary, $e author").unwrap();
        assert_eq!(
            AuthorRoles::from(&record),
            AuthorRoles {
                primary_author: Some("Primary".to_owned()),
                ..Default::default()
            }
        )
    }

    #[test]
    fn it_can_find_all_types_of_author() {
        let record = Record::from_breaker(
            r#"=100 \\$aLahiri, Jhumpa
=700 \\$aEugenides, Jeffrey$4edt
=700 \\$aCole, Teju$4com
=700 \\$aNikolakopoulou, Evangelia$4trl
=700 \\$aMorrison, Toni$4aaa
=700 \\$aOates, Joyce Carol
=700 \\$aMarchesi, Simone$etranslator.
=700 \\$aFitzgerald, F. Scott$eed."#,
        )
        .unwrap();
        assert_eq!(
            AuthorRoles::from(&record),
            AuthorRoles {
                primary_author: Some("Lahiri, Jhumpa".to_owned()),
                secondary_authors: vec![
                    "Morrison, Toni".to_owned(),
                    "Oates, Joyce Carol".to_owned(),
                    "Fitzgerald, F. Scott".to_owned()
                ],
                translators: vec![
                    "Nikolakopoulou, Evangelia".to_owned(),
                    "Marchesi, Simone".to_owned()
                ],
                editors: vec!["Eugenides, Jeffrey".to_owned()],
                compilers: vec!["Cole, Teju".to_owned()]
            }
        )
    }
}
