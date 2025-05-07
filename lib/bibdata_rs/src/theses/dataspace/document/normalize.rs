// This module is responsible for normalizing data within a DataspaceDocument

use crate::theses::{
    dataspace::document::{restrictions, DataspaceDocument},
    department, embargo, holdings, language, looks_like_yes, program,
};
use itertools::Itertools;
use regex::{Captures, Regex};

impl DataspaceDocument {
    pub fn access_facet(&self) -> Option<String> {
        if self.has_current_embargo() {
            None
        } else if self.on_site_only() {
            Some("In the Library".to_owned())
        } else {
            Some("Online".to_owned())
        }
    }

    pub fn advanced_location(&self) -> Option<Vec<String>> {
        if self.has_current_embargo() || self.on_site_only() {
            Some(vec![
                "mudd$stacks".to_owned(),
                "Mudd Manuscript Library".to_owned(),
            ])
        } else {
            None
        }
    }

    pub fn all_authors(&self) -> Vec<String> {
        let mut authors = self.contributor_author.clone().unwrap_or_default().clone();
        authors.extend(self.contributor_advisor.clone().unwrap_or_default());
        authors.extend(self.contributor.clone().unwrap_or_default());
        authors.extend(
            self.department
                .clone()
                .unwrap_or_default()
                .iter()
                .filter_map(|dept| department::map_department(dept)),
        );
        authors.extend(
            self.certificate
                .clone()
                .unwrap_or_default()
                .iter()
                .filter_map(|program| program::map_program(program)),
        );
        authors
    }

    pub fn ark_hash(&self) -> Option<String> {
        holdings::ark_hash(
            self.identifier_uri.clone(),
            self.location.is_some(),
            self.rights_access_rights.is_some(),
            self.mudd_walkin.clone(),
            self.date_classyear.clone()?,
            self.embargo_lift.clone(),
            self.embargo_terms.clone(),
        )
    }

    pub fn authorized_ceritificates(&self) -> Option<Vec<String>> {
        self.certificate.as_ref().map(|certificates| {
            certificates
                .iter()
                .filter_map(|certificate| program::map_program(certificate))
                .collect()
        })
    }

    pub fn authorized_departments(&self) -> Option<Vec<String>> {
        self.department.as_ref().map(|departments| {
            departments
                .iter()
                .filter_map(|department| department::map_department(department))
                .collect()
        })
    }

    pub fn call_number(&self) -> String {
        holdings::call_number(self.identifier_other.as_ref())
    }

    pub fn class_year(&self) -> Option<Vec<String>> {
        let years = self.date_classyear.clone().unwrap_or_default();
        let year = years.first()?;
        if year.chars().all(|c| c.is_numeric()) {
            Some(vec![year.to_string()])
        } else {
            None
        }
    }

    pub fn languages(&self) -> Vec<String> {
        language::codes_to_english_names(self.language_iso.clone())
    }

    pub fn location(&self) -> Option<String> {
        if self.has_current_embargo() || self.on_site_only() {
            Some("Mudd Manuscript Library".to_owned())
        } else {
            None
        }
    }

    pub fn location_code(&self) -> Option<String> {
        if self.has_current_embargo() || self.on_site_only() {
            Some("mudd$stacks".to_owned())
        } else {
            None
        }
    }

    pub fn on_site_only(&self) -> bool {
        holdings::on_site_only(
            self.location.is_some(),
            self.rights_access_rights.is_some(),
            self.mudd_walkin.clone(),
            self.date_classyear.clone().unwrap_or_default(),
            self.embargo_lift.clone(),
            self.embargo_terms.clone(),
        )
    }

    pub fn online_portfolio_statements(&self) -> Option<String> {
        if self.on_site_only() || self.has_current_embargo() {
            None
        } else {
            holdings::online_holding_string(
                self.identifier_other.as_ref(),
            )    
        }
    }

    pub fn restrictions_note_display(&self) -> Option<Vec<String>> {
        if self.location.is_some() || self.rights_access_rights.is_some() {
            Some(restrictions::restrictions_access(
                self.location.clone().unwrap_or_default().first().cloned(),
                self.rights_access_rights
                    .clone()
                    .unwrap_or_default()
                    .first()
                    .cloned(),
            ))
        } else if looks_like_yes(self.mudd_walkin.clone()) {
            Some(vec!["Walk-in Access. This thesis can only be viewed on computer terminals at the '<a href=\"http://mudd.princeton.edu\">Mudd Manuscript Library</a>.".to_owned()])
        } else if embargo::has_embargo_date(self.embargo_lift.clone(), self.embargo_terms.clone()) {
            if embargo::has_parseable_embargo_date(
                self.embargo_lift.clone(),
                self.embargo_terms.clone(),
            ) {
                Some(vec![embargo::embargo_text(
                    self.embargo_lift.clone(),
                    self.embargo_terms.clone(),
                    self.id.clone().unwrap_or_default(),
                )])
            } else {
                Some(vec![
                    format!("This content is currently under embargo. For more information contact the <a href=\"mailto:dspadmin@princeton.edu?subject=Regarding embargoed DataSpace Item 88435/{}\"> Mudd Manuscript Library</a>.", self.id.clone().unwrap_or_default())
                ])
            }
        } else {
            None
        }
    }

    /// Take first title, strip out latex expressions when present to include along
    /// with non-normalized version (allowing users to get matches both when LaTex
    /// is pasted directly into the search box and when sub/superscripts are placed
    /// adjacent to regular characters
    pub fn title_search_versions(&self) -> Option<Vec<String>> {
        match &self.title {
            Some(titles) => titles.first().map(|title| {
                vec![title.to_string(), normalize_latex(title)]
                    .into_iter()
                    .unique()
                    .collect()
            }),
            None => None,
        }
    }

    fn has_current_embargo(&self) -> bool {
        embargo::has_current_embargo(self.embargo_lift.clone(), self.embargo_terms.clone())
    }
}

fn normalize_latex(original: &str) -> String {
    Regex::new(r"\\\(.*?\\\)")
        .unwrap()
        .replace_all(original, |captures: &Captures| {
            captures[0]
                .chars()
                .filter(|c| c.is_alphanumeric())
                .collect::<String>()
        })
        .to_string()
}

#[cfg(test)]
mod tests {
    use super::*;
    #[test]
    fn it_normalizes_latex() {
        assert_eq!(
            normalize_latex("2D \\(^{1}\\)H-\\(^{14}\\)N HSQC inverse-detection experiments"),
            "2D 1H-14N HSQC inverse-detection experiments"
        );
    }

    #[test]
    fn ark_hash_gets_the_ark_with_fulltext_link_display_when_restrictions() {
        let metadata = DataspaceDocument::builder()
            .with_id("dsp01b2773v788")
            .with_description_abstract("Summary")
            .with_contributor("Wolff, Tamsen".to_string())
            .with_contributor_advisor("Sandberg, Robert".to_string())
            .with_contributor_author("Clark, Hillary".to_string())
            .with_date_classyear("2014")
            .with_department("Princeton University. Department of English")
            .with_department("Princeton University. Program in Theater")
            .with_identifier_uri("http://arks.princeton.edu/ark:/88435/dsp01b2773v788")
            .with_format_extent("102 pages")
            .with_language_iso("en_US")
            .with_title("Dysfunction: A Play in One Act")
            .build();

        assert_eq!(
            metadata.ark_hash().unwrap(),
            r#"{"http://arks.princeton.edu/ark:/88435/dsp01b2773v788":["DataSpace","Full text"]}"#
        );
    }

    #[test]
    fn ark_hash_gets_the_ark_with_fulltext_link_display_when_no_restrictions() {
        let metadata = DataspaceDocument::builder()
            .with_id("dsp01b2773v788")
            .with_description_abstract("Summary")
            .with_contributor("Wolff, Tamsen".to_string())
            .with_contributor_advisor("Sandberg, Robert".to_string())
            .with_contributor_author("Clark, Hillary".to_string())
            .with_date_classyear("2014")
            .with_department("Princeton University. Department of English")
            .with_department("Princeton University. Program in Theater")
            .with_identifier_uri("http://arks.princeton.edu/ark:/88435/dsp01b2773v788")
            .with_format_extent("102 pages")
            .with_language_iso("en_US")
            .with_title("Dysfunction: A Play in One Act")
            .build();

        assert_eq!(
            metadata.ark_hash().unwrap(),
            r#"{"http://arks.princeton.edu/ark:/88435/dsp01b2773v788":["DataSpace","Full text"]}"#
        );
    }

    #[test]
    fn ark_hash_returns_none_when_no_url() {
        let metadata = DataspaceDocument::builder()
            .with_id("dsp01b2773v788")
            .with_description_abstract("Summary")
            .with_contributor("Wolff, Tamsen".to_string())
            .with_contributor_advisor("Sandberg, Robert".to_string())
            .with_contributor_author("Clark, Hillary".to_string())
            .with_date_classyear("2014")
            .with_department("Princeton University. Department of English")
            .with_department("Princeton University. Program in Theater")
            .with_format_extent("102 pages".to_string())
            .with_language_iso("en_US")
            .with_title("Dysfunction: A Play in One Act")
            .build();

        assert_eq!(metadata.ark_hash(), None);
    }

    #[test]
    fn on_site_only() {
        assert!(
            DataspaceDocument::builder()
                .with_embargo_terms("2100-01-01")
                .build()
                .on_site_only(),
            "doc with embargo terms field should return true"
        );
        assert!(
            DataspaceDocument::builder()
                .with_embargo_lift("2100-01-01")
                .build()
                .on_site_only(),
            "doc with embargo lift field should return true"
        );
        assert!(
            DataspaceDocument::builder()
                .with_embargo_lift("2000-01-01")
                .with_mudd_walkin("yes")
                .with_date_classyear("2012-01-01T00:00:00Z")
                .build()
                .on_site_only(),
            "with a specified accession date prior to 2013, it should return true"
        );

        assert!(
            !DataspaceDocument::builder()
                .with_location("physical location")
                .build()
                .on_site_only(),
            "doc with location field should return false"
        );
        assert!(
            !DataspaceDocument::builder()
                .with_embargo_lift("2000-01-01")
                .build()
                .on_site_only(),
            "doc with expired embargo lift field should return false"
        );
        assert!(
            !DataspaceDocument::builder()
                .with_embargo_lift("2000-01-01")
                .with_mudd_walkin("yes")
                .build()
                .on_site_only(),
            "without a specified accession date, it should return false"
        );
        assert!(
            !DataspaceDocument::builder()
                .with_embargo_lift("2000-01-01")
                .with_mudd_walkin("yes")
                .with_date_classyear("2013-01-01T00:00:00Z")
                .build()
                .on_site_only(),
            "with a specified accession date in 2013, it should return false"
        );
        assert!(
            !DataspaceDocument::builder().build().on_site_only(),
            "doc with no access-related fields should return false"
        );
        assert!(!DataspaceDocument::builder().build().on_site_only());
    }

    mod all_authors {
        use super::*;

        #[test]
        fn it_includes_author() {
            let document = DataspaceDocument::builder()
                .with_contributor_author("Turing, Alan")
                .build();
            assert_eq!(document.all_authors(), vec!["Turing, Alan".to_owned()]);
        }

        #[test]
        fn it_includes_normalized_department() {
            let document = DataspaceDocument::builder()
                .with_department("Astrophysical Sciences")
                .build();
            assert_eq!(
                document.all_authors(),
                vec!["Princeton University. Department of Astrophysical Sciences".to_owned()]
            );
        }

        #[test]
        fn it_includes_normalized_certificate() {
            let document = DataspaceDocument::builder()
                .with_certificate("Hellenic Studies Program")
                .build();
            assert_eq!(
                document.all_authors(),
                vec!["Princeton University. Program in Hellenic Studies".to_owned()]
            );
        }
    }
}
