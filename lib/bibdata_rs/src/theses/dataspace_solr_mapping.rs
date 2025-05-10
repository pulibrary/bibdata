use crate::theses::{dataspace::document::DataspaceDocument, holdings, solr};

impl From<DataspaceDocument> for solr::SolrDocument {
    fn from(value: DataspaceDocument) -> Self {
        let binding = value.title.clone().unwrap_or_default();
        let first_title = binding.first();
        solr::SolrDocument::builder()
            .with_id(value.id.clone().unwrap_or_default())
            .with_access_facet(value.access_facet())
            .with_advanced_location_s(value.advanced_location())
            .with_advisor_display(value.contributor_advisor.clone())
            .with_author_display(value.contributor_author.clone())
            .with_author_s(value.all_authors())
            .with_author_sort(&value.contributor_author.clone().unwrap_or_default().first())
            .with_call_number_browse_s(value.call_number())
            .with_call_number_display(value.call_number())
            .with_certificate_display(value.authorized_ceritificates())
            .with_contributor_display(value.contributor.clone())
            .with_department_display(value.authorized_departments())
            .with_holdings_1display(holdings::physical_holding_string(value.identifier_uri.clone()))
            .with_location(value.location())
            .with_location_code_s(value.location_code())
            .with_location_display(value.location())
            .with_electronic_access_1display(&value.ark_hash())
            .with_electronic_portfolio_s(holdings::online_holding_string(value.identifier_other.clone()))
            .with_restrictions_note_display(value.restrictions_note_display())
            .with_title_citation_display(&first_title)
            .with_title_display(&first_title)
            .with_title_sort(&title_sort(&value.title))
            .with_title_t(&value.title_search_versions())
            .with_language_facet(value.languages())
            .with_language_name_display(value.languages())
            .with_class_year_s(&value.class_year())
            .with_pub_date_start_sort(&value.class_year())
            .with_pub_date_end_sort(&value.class_year())
            .with_description_display(value.format_extent)
            .with_summary_note_display(value.description_abstract)
            .build()
    }
}


fn title_sort(titles: &Option<Vec<String>>) -> Option<String> {
    match titles {
        Some(title_vec) => {
            let first = title_vec.first()?;
            Some(
                first
                    .to_lowercase()
                    .chars()
                    .filter(|c| !c.is_ascii_punctuation())
                    .collect::<String>()
                    .trim_start_matches("a ")
                    .trim_start_matches("an ")
                    .trim_start_matches("the ")
                    .chars()
                    .filter(|c| !c.is_whitespace())
                    .collect::<String>()
            )
        }
        None => None,
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn it_can_convert_into_solr_document() {
        let metadata = DataspaceDocument::builder()
            .with_id("dsp01b2773v788")
            .with_description_abstract("Summary")
            .with_contributor("Wolff, Tamsen".to_string())
            .with_contributor_advisor("Sandberg, Robert".to_string())
            .with_contributor_author("Clark, Hillary".to_string())
            .with_date_classyear("2014")
            .with_department("Princeton University. Department of English")
            .with_department("Princeton University. Program in Theater")
            .with_format_extent("102 pages")
            .with_language_iso("en_US")
            .with_title("Dysfunction: A Play in One Act".to_string())
            .build();

        let solr = solr::SolrDocument::from(metadata);

        assert_eq!(solr.id, "dsp01b2773v788");
        assert_eq!(solr.title_t.unwrap(), vec!["Dysfunction: A Play in One Act"]);
        assert_eq!(solr.title_citation_display.unwrap(), "Dysfunction: A Play in One Act");
        assert_eq!(solr.title_display.unwrap(), "Dysfunction: A Play in One Act");
        assert_eq!(solr.title_sort.unwrap(), "dysfunctionaplayinoneact");
    }
    
    #[test]
    fn it_adds_the_expected_fields() {
        let document = DataspaceDocument::builder()
            .with_id("dsp01b2773v788")
            .with_description_abstract("Summary")
            .with_contributor("Wolff, Tamsen")
            .with_contributor_advisor("Sandberg, Robert")
            .with_contributor_author("Clark, Hillary")
            .with_identifier_uri("http://arks.princeton.edu/ark:/88435/dsp01b2773v788")
            .with_format_extent("102 pages")
            .with_language_iso("en_US")
            .with_title("Dysfunction: A Play in One Act")
            .with_date_classyear("2014")
            .with_department("Princeton University. Department of English")
            .with_department("Princeton University. Program in Theater")
            .with_rights_access_rights("Walk-in Access...")
            .build();
        let solr = solr::SolrDocument::from(document);
        assert_eq!(solr.author_display, Some(vec!["Clark, Hillary".to_owned()]));
        assert_eq!(
            solr.author_s.unwrap().sort(),
            vec!["Clark, Hillary".to_owned(), "Sandberg, Robert".to_owned(), "Wolff, Tamsen".to_owned()].sort()
        );
        assert_eq!(solr.summary_note_display, Some(vec!["Summary".to_owned()]))
    }

    #[test]
    fn it_is_senior_thesis() {
        let document = DataspaceDocument::builder().build();
        let solr = solr::SolrDocument::from(document);
        assert_eq!(solr.format, "Senior thesis");
    }

    #[test]
    fn integer_in_classyear_field() {
        let document = DataspaceDocument::builder().with_date_classyear("2014").build();
        let solr = solr::SolrDocument::from(document);
        assert_eq!(solr.class_year_s.unwrap(), vec!["2014".to_owned()]);
        assert_eq!(solr.pub_date_start_sort.unwrap(), vec!["2014".to_owned()]);
        assert_eq!(solr.pub_date_end_sort.unwrap(), vec!["2014".to_owned()]);
    }


    #[test]
    fn non_integer_in_classyear_field() {
        let document = DataspaceDocument::builder().with_date_classyear("Undated").build();
        let solr = solr::SolrDocument::from(document);
        assert!(solr.class_year_s.is_none());
        assert!(solr.pub_date_start_sort.is_none());
        assert!(solr.pub_date_end_sort.is_none());
    }

    #[test]
    fn no_classyear() {
        let document = DataspaceDocument::builder().build();
        let solr = solr::SolrDocument::from(document);
        assert!(solr.class_year_s.is_none());
        assert!(solr.pub_date_start_sort.is_none());
        assert!(solr.pub_date_end_sort.is_none());
    }

    #[test]
    fn with_access_rights() {
        let document = DataspaceDocument::builder().with_rights_access_rights("Walk-in Access...").build();
        let solr = solr::SolrDocument::from(document);
        assert_eq!(solr.access_facet.unwrap(), "Online");
        assert!(solr.advanced_location_s.is_none());
    }

    #[test]
    fn with_embargo() {
        let document = DataspaceDocument::builder()
            .with_rights_access_rights("Walk-in Access...")
            .with_embargo_terms("2100-01-01")
            .build();
        let solr = solr::SolrDocument::from(document);
        assert!(solr.access_facet.is_none());
        assert_eq!(solr.advanced_location_s.unwrap(), vec!["mudd$stacks".to_owned(), "Mudd Manuscript Library".to_owned()]);
    }

    #[test]
    fn it_has_electronic_portfolio_s_by_default() {
        let document = DataspaceDocument::builder().build();
        let solr = solr::SolrDocument::from(document);
        assert_eq!(solr.access_facet.unwrap(), "Online");
        assert!(solr.electronic_portfolio_s.unwrap().contains("thesis"));
    }

    #[test]
    fn with_allowed_department_name() {
        let document = DataspaceDocument::builder().with_department("English").build();
        let solr = solr::SolrDocument::from(document);
        assert_eq!(solr.department_display.unwrap(), vec!["Princeton University. Department of English"], "it should map to the LC authorized name for the department");
    }

    #[test]
    fn with_disallowed_department_name() {
        let document = DataspaceDocument::builder().with_department("NA").build();
        let solr = solr::SolrDocument::from(document);
        assert!(solr.department_display.unwrap().is_empty(), "it should not include department names that are not in the authorized list");
    }

    #[test]
    fn with_multiple_allowed_department_names() {
        let document = DataspaceDocument::builder()
            .with_department("English")
            .with_department("German")
            .build();
        let solr = solr::SolrDocument::from(document);
        assert_eq!(
            solr.department_display.unwrap(),
            vec!["Princeton University. Department of English", "Princeton University. Department of Germanic Languages and Literatures"],
            "it should map to all LC authorized department names"
        );
    }

    #[test]
    fn with_allowed_certificate_name() {
        let document = DataspaceDocument::builder().with_certificate("Creative Writing Program").build();
        let solr = solr::SolrDocument::from(document);
        assert_eq!(solr.certificate_display.unwrap(), vec!["Princeton University. Creative Writing Program"], "it should map to the LC authorized name for the program");
    }

    #[test]
    fn with_disallowed_certificate_name() {
        let document = DataspaceDocument::builder().with_certificate("NA").build();
        let solr = solr::SolrDocument::from(document);
        assert!(solr.certificate_display.unwrap().is_empty(), "it should not include program names that are not in the authorized list");
    }

    #[test]
    fn with_multiple_allowed_certificate_names() {
        let document = DataspaceDocument::builder()
            .with_certificate("Environmental Studies Program")
            .with_certificate("African Studies Program")
            .build();
        let solr = solr::SolrDocument::from(document);
        assert_eq!(
            solr.certificate_display.unwrap(),
            vec!["Princeton University. Program in Environmental Studies", "Princeton University. Program in African Studies"],
            "it should map to all LC authorized program names"
        );
    }

    mod restrictions_note_display {
        use super::*;

        #[test]
        fn when_lift_date_is_invalid() {
            let document = DataspaceDocument::builder()
                .with_id("test-id")
                .with_embargo_lift("invalid")
                .build();
            let solr = solr::SolrDocument::from(document);
            assert_eq!(solr.restrictions_note_display.unwrap(), vec!["This content is currently under embargo. For more information contact the <a href=\"mailto:dspadmin@princeton.edu?subject=Regarding embargoed DataSpace Item 88435/test-id\"> Mudd Manuscript Library</a>."]);
        }

        #[test]
        fn when_terms_date_is_invalid() {
            let document = DataspaceDocument::builder()
                .with_id("test-id")
                .with_embargo_terms("invalid")
                .build();
            let solr = solr::SolrDocument::from(document);
            assert_eq!(solr.restrictions_note_display.unwrap(), vec!["This content is currently under embargo. For more information contact the <a href=\"mailto:dspadmin@princeton.edu?subject=Regarding embargoed DataSpace Item 88435/test-id\"> Mudd Manuscript Library</a>."]);
        }

        #[test]
        fn when_there_are_access_rights() {
            let document = DataspaceDocument::builder()
                .with_id("test-id")
                .with_rights_access_rights("Walk-in Access. This thesis can only be viewed on computer terminals at the <a href=http://mudd.princeton.edu>Mudd Manuscript Library</a>.")
                .build();
            let solr = solr::SolrDocument::from(document);
            assert_eq!(solr.restrictions_note_display.unwrap(), vec!["Walk-in Access. This thesis can only be viewed on computer terminals at the <a href=http://mudd.princeton.edu>Mudd Manuscript Library</a>."]);
        }
    }

    mod title_sort {
        use super::*;

        #[test]
        fn it_can_create_sortable_version_of_title() {
            assert_eq!(
                title_sort(&Some(vec!["\"Some quote\" : Blah blah".to_owned()])).unwrap(),
                "somequoteblahblah",
                "it should strip punctuation"
            );
            assert_eq!(
                title_sort(&Some(vec!["A title : blah blah".to_owned()])).unwrap(),
                "titleblahblah",
                "it should strip articles"
            );
            assert_eq!(
                title_sort(&Some(vec!["\"A quote\" : Blah blah".to_owned()])).unwrap(),
                "quoteblahblah",
                "it should strip punctuation and articles"
            );
            assert_eq!(
                title_sort(&Some(vec!["thesis".to_owned()])).unwrap(),
                "thesis",
                "it should leave words that start with articles alone"
            );
        }
    }
}
