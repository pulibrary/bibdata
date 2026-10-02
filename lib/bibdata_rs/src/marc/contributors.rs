use crate::marc::{
    extract_values::ExtractValues,
    string_normalize::maybe_not_empty,
    trim_punctuation,
    variable_length_field::{SubfieldIterator, extract_marc, latin_tag_included_in},
};
use crate::solr::AuthorRoles;
use itertools::Itertools;
use marctk::{Field, Record};

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

pub fn author_citation_display(record: &Record) -> Vec<String> {
    extract_marc!(latin "100a", "110a", "111a", "700a", "710a", "711a")(record)
        .iter()
        .map(|author| trim_punctuation(author))
        .collect()
}

pub fn author_sort_key(record: &Record) -> Option<String> {
    let authors = extract_marc!("100aqbcdk", "110abcdfgkln", "111abcdfgklnpq")(record);
    authors.first().map(|name| {
        name.chars()
            .filter(|c| c.is_alphabetic() || c == &' ')
            .collect::<String>()
            .trim()
            .to_owned()
    })
}

pub fn author_s(record: &Record) -> impl Iterator<Item = String> {
    record
        .extract_field_values_by(
            latin_tag_included_in(&["100", "110", "111", "700", "710", "711"]),
            author_info_from_field,
        )
        .unique()
}

fn author_info_from_field(field: &Field) -> Option<String> {
    let desired_subfields = match field.tag() {
        "100" | "700" => vec!["a", "q", "b", "c", "d", "k"],
        "110" | "710" => vec!["a", "b", "c", "d", "f", "g", "k", "l", "n"],
        "111" | "711" => vec!["a", "b", "c", "d", "f", "g", "k", "l", "n", "p", "q"],
        _ => return None,
    };
    let joined = field
        .subfields()
        .iter()
        .subfields_before("t")
        .filter_by_code(&desired_subfields)
        .join(" ");
    maybe_not_empty(trim_punctuation(&joined))
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

    #[test]
    fn it_normalizes_authors_for_sorting() {
        let record = Record::from_breaker(r#"=100 \\$aBhaṭanāgara, Mahendra, $d 1926-"#).unwrap();
        assert_eq!(
            author_sort_key(&record),
            Some(String::from("Bhaṭanāgara Mahendra"))
        )
    }

    #[test]
    fn it_extracts_author_citation_from_all_roles_in_order() {
        let record = Record::from_breaker(
            r#"=100 \\$aSingh, Digvijai,
=110 \\$aKant, Immanuel
=111 \\$aWorld Conference on Women, 1st:
=700 \\$aIshizuka, Harumichi
=710 \\$aNational Aeronautics and Space Administration
=711 \\$aSymposium on Quantum Computing, 3rd"#,
        )
        .unwrap();
        assert_eq!(
            author_citation_display(&record),
            vec![
                "Singh, Digvijai".to_owned(),
                "Kant, Immanuel".to_owned(),
                "World Conference on Women, 1st".to_owned(),
                "Ishizuka, Harumichi".to_owned(),
                "National Aeronautics and Space Administration".to_owned(),
                "Symposium on Quantum Computing, 3rd".to_owned(),
            ]
        )
    }

    #[test]
    fn it_excludes_alternate_script_for_author_citation() {
        let record = Record::from_breaker(
            r#"=100 \\$aSingh, Digvijai
=880 \\$aসিংহ, দিবজাই"#,
        )
        .unwrap();
        assert_eq!(
            author_citation_display(&record),
            vec!["Singh, Digvijai".to_owned()]
        );
    }

    #[test]
    fn it_returns_empty_when_no_author_fields_present() {
        let record = Record::from_breaker(r#"=245 10 \\$aA title"#).unwrap();
        assert_eq!(author_citation_display(&record), Vec::<String>::new());
    }

    #[test]
    fn it_joins_pre_t_subfields_and_stops_at_t() {
        let record = Record::from_breaker(
            r#"=100 \\$aJohn$d1492$tTitle$kignored
=700 \\$aJohn$d1492$kdont ignore$tTitle"#,
        )
        .unwrap();
        assert_eq!(
            author_s(&record).collect::<Vec<_>>(),
            vec!["John 1492".to_owned(), "John 1492 dont ignore".to_owned()]
        );
    }

    #[test]
    fn it_deduplicates_names_from_multiple_fields() {
        let record = Record::from_breaker(
            r#"=100 \\$aDoe, John
=700 \\$aDoe, John"#,
        )
        .unwrap();
        assert_eq!(
            author_s(&record).collect::<Vec<_>>(),
            vec!["Doe, John".to_owned()]
        );
    }

    #[test]
    fn it_ignores_880_parallel_names() {
        let record = Record::from_breaker(
            r#"=100 \\$aZhang, Liwei
=880 \\$6100-01$a張，立偉"#,
        )
        .unwrap();
        assert_eq!(
            author_s(&record).collect::<Vec<_>>(),
            vec!["Zhang, Liwei".to_owned()]
        );
    }

    #[test]
    fn it_handles_corporate_and_meeting_names() {
        let record = Record::from_breaker(
            r#"=110 \\$aWorld Data Center A for Glaciology
=111 \\$aWorld Conference on Women, 1st
=710 \\$aNational Aeronautics and Space Administration
=711 \\$aSymposium on Quantum Computing, 3rd"#,
        )
        .unwrap();
        assert_eq!(
            author_s(&record).collect::<Vec<_>>(),
            vec![
                "World Data Center A for Glaciology".to_owned(),
                "World Conference on Women, 1st".to_owned(),
                "National Aeronautics and Space Administration".to_owned(),
                "Symposium on Quantum Computing, 3rd".to_owned(),
            ]
        );
    }

    #[test]
    fn it_skips_a_name_field_with_no_subfields_before_t() {
        let record = Record::from_breaker(r#"=700 \\$tShould not include$aWhen no name"#).unwrap();
        assert_eq!(author_s(&record).collect::<Vec<_>>(), Vec::<String>::new());
    }

    #[test]
    fn it_dedupes_names() {
        let record = Record::from_breaker(
            r#"=100 \\$aSánchez Alegría, María José,$d1965-
=700 \\$aSánchez Alegría, María José,$d1965-"#,
        )
        .unwrap();
        assert_eq!(
            author_s(&record).collect::<Vec<_>>(),
            vec!["Sánchez Alegría, María José, 1965-".to_owned()]
        );
    }
}
