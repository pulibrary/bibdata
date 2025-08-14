use super::SolrDocument;
use crate::ephemera::ephemera_folder::EphemeraFolder;

impl From<&EphemeraFolder> for SolrDocument {
    fn from(value: &EphemeraFolder) -> Self {
        SolrDocument::builder()
            .with_access_facet(value.access_facet())
            .with_author_display(Some(value.all_contributors()))
            .with_author_roles_1display(value.first_contibutor())
            .with_author_s(value.creator.clone().unwrap_or_default())
            .with_author_sort(value.creator.clone().unwrap_or_default().first().cloned())
            .with_author_citation_display(value.creator.clone())
            .with_description_display(Some(value.concat_page_count()))
            .with_electronic_access_1display(value.electronic_access())
            .with_format(value.solr_formats())
            .with_geographic_facet(Some(value.coverage_labels()))
            .with_homoit_subject_display(value.subject_labels())
            .with_homoit_subject_facet(value.subject_labels())
            .with_id(value.normalized_id())
            .with_language_facet(value.language_labels())
            .with_language_name_display(value.language_labels())
            .with_lc_subject_display(value.subject_labels())
            .with_lc_subject_facet(value.subject_labels())
            .with_notes(value.description.clone())
            .with_notes_display(value.description.clone())
            .with_other_title_display(Some(value.other_title_display_combined()))
            .with_provenance_display(value.provenance.clone())
            .with_pub_citation_display(value.origin_place_publisher_date_created_combined())
            .with_pub_date_display(value.date_created_publisher_combined())
            .with_publication_location_citation_display(value.origin_place_labels())
            .with_pub_date_start_sort(value.date_created_year())
            .with_pub_created_display(value.publisher.clone())
            .with_publisher_no_display(value.publisher.clone())
            .with_publisher_citation_display(value.publisher.clone())
            .with_title_display(value.title.first().cloned())
            .with_title_sort(value.first_sort_title())
            .with_title_citation_display(value.title.first().cloned())
            .build()
    }
}

#[cfg(test)]
mod tests {

    use crate::ephemera::ephemera_folder::country;
    use crate::ephemera::ephemera_folder::coverage::Coverage;
    use crate::ephemera::ephemera_folder::origin_place::OriginPlace;
    use crate::ephemera_folder::subject::ExactMatch;
    use crate::ephemera_folder::subject::Subject;
    use crate::{ephemera::ephemera_folder::format::Format, solr};
    use std::{fs::File, io::BufReader, str::FromStr};

    use super::*;

    #[test]
    fn it_has_alternative_title_display() {
        let document = EphemeraFolder::builder()
            .id("af4a941d-96a4-463e-9043-cfa512e5eddd".to_string())
            .title(vec!["title1".to_string()])
            .alternative(vec!["alternativeTestTitle".to_string()])
            .transliterated_title(vec!["test title display".to_string()])
            .build()
            .unwrap();
        let solr = SolrDocument::from(&document);
        assert_eq!(
            solr.other_title_display,
            Some(vec![
                "alternativeTestTitle".to_string(),
                "test title display".to_string()
            ])
        );
    }

    #[test]
    fn it_combines_alternative_and_transliterated_title_into_other_title_display() {
        let item = EphemeraFolder::builder()
            .id("12345".to_string())
            .title(vec!["Bohemian Rhapsody".to_string()])
            .alternative(vec!["We are the champions!".to_string()])
            .transliterated_title(vec!["Another one bites the dust".to_string()])
            .build()
            .unwrap();
        let solr = SolrDocument::from(&item);
        assert_eq!(
            solr.other_title_display,
            Some(vec![
                "We are the champions!".to_string(),
                "Another one bites the dust".to_string()
            ])
        );
    }

    #[test]
    fn it_can_convert_figgy_json_into_solr() {
        let fixture = File::open("../../spec/fixtures/files/ephemera/ephemera1.json").unwrap();
        let reader = BufReader::new(fixture);
        let ephemera_item: EphemeraFolder = serde_json::from_reader(reader).unwrap();
        let solr_document: SolrDocument = SolrDocument::from(&ephemera_item);
        assert_eq!(
            solr_document.title_citation_display,
            Some(
                "Of technique : chance procedures on turntable : a book of essays & illustrations"
                    .to_string()
            )
        );
        assert_eq!(
            solr_document.other_title_display,
            Some(vec![
                "Chance procedures on turntable".to_owned(),
                "custom transliterated title".to_owned()
            ])
        );
        assert_eq!(
            solr_document.id,
            "af4a941d-96a4-463e-9043-cfa512e5eddd".to_string()
        );
        assert_eq!(
            solr_document.description_display,
            Some(vec!["pages: 116".to_string()])
        )
    }

    #[test]
    fn it_has_the_id_from_the_ephemera_folder_item() {
        let ephemera_item = EphemeraFolder::builder()
            .id("abc123".to_owned())
            .title(vec!["Our favorite book".to_owned()])
            .build()
            .unwrap();
        let solr_document = SolrDocument::from(&ephemera_item);
        assert_eq!(solr_document.id, "abc123");
    }

    #[test]
    fn it_has_the_description_from_the_ephemera_folder_item() {
        let ephemera_item = EphemeraFolder::builder()
            .id("abc123".to_owned())
            .title(vec!["Our favorite book".to_owned()])
            .description(vec!["Puppy biting".to_owned()])
            .build()
            .unwrap();
        let solr_document = SolrDocument::from(&ephemera_item);
        assert_eq!(
            solr_document.notes_display,
            Some(vec!["Puppy biting".to_owned()])
        );
    }

    #[test]
    fn it_has_the_creator_from_the_ephemera_folder_item() {
        let ephemera_item = EphemeraFolder::builder()
            .id("abc123".to_owned())
            .title(vec!["Our favorite book".to_owned()])
            .creator(vec!["Aspen".to_owned()])
            .build()
            .unwrap();
        let solr_document = SolrDocument::from(&ephemera_item);
        assert_eq!(solr_document.author_display, Some(vec!["Aspen".to_owned()]));
        assert_eq!(solr_document.author_sort, Some("Aspen".to_owned()));
        assert_eq!(
            solr_document.author_roles_1display,
            Some("Aspen".to_owned())
        );
        assert_eq!(
            solr_document.author_citation_display,
            Some(vec!["Aspen".to_owned()])
        );
    }

    #[test]
    fn it_has_the_contributor_from_the_ephemera_folder_item() {
        let ephemera_item = EphemeraFolder::builder()
            .id("abc123".to_owned())
            .title(vec!["Our favorite book".to_owned()])
            .creator(vec!["Aspen".to_owned()])
            .contributor(vec!["Tiberius".to_owned()])
            .build()
            .unwrap();
        let solr_document = SolrDocument::from(&ephemera_item);
        assert_eq!(
            solr_document.author_display,
            Some(vec!["Aspen".to_owned(), "Tiberius".to_owned()])
        );
    }

    #[test]
    fn it_uses_contributor_as_a_fallback_value_for_the_author_roles_1display_field() {
        let ephemera_item = EphemeraFolder::builder()
            .id("abc123".to_owned())
            .title(vec!["Our favorite book".to_owned()])
            .contributor(vec!["Tiberius".to_owned()])
            .build()
            .unwrap();
        let solr_document = SolrDocument::from(&ephemera_item);
        assert_eq!(
            solr_document.author_roles_1display,
            Some("Tiberius".to_owned())
        );
    }

    #[test]
    fn it_has_the_format_from_the_ephemera_folder_item() {
        let ephemera_item = EphemeraFolder::builder()
            .id("abc123".to_owned())
            .title(vec!["Our favorite book".to_owned()])
            .format(vec![Format {
                pref_label: Some(solr::FormatFacet::from_str("Serials").unwrap()),
            }])
            .build()
            .unwrap();
        let solr_document = SolrDocument::from(&ephemera_item);
        assert_eq!(solr_document.format, Some(vec![solr::FormatFacet::Journal]))
    }

    #[test]
    fn it_has_the_provenance_from_the_ephemera_folder_item() {
        let ephemera_item = EphemeraFolder::builder()
            .id("abc123".to_owned())
            .title(vec!["Our favorite book".to_owned()])
            .provenance("Test name".to_owned())
            .build()
            .unwrap();
        let solr_document = SolrDocument::from(&ephemera_item);
        assert_eq!(solr_document.id, "abc123");
        assert_eq!(
            solr_document.provenance_display,
            Some("Test name".to_owned())
        );
    }
    #[test]
    fn it_has_the_publisher_from_the_ephemera_folder_item() {
        let ephemera_item = EphemeraFolder::builder()
            .id("abc123".to_owned())
            .title(vec!["Our favorite book".to_owned()])
            .publisher(vec!["Princeton Press".to_owned()])
            .build()
            .unwrap();
        let solr_document = SolrDocument::from(&ephemera_item);
        assert_eq!(
            solr_document.pub_created_display,
            Some(vec!["Princeton Press".to_owned()])
        );
        assert_eq!(
            solr_document.publisher_no_display,
            Some(vec!["Princeton Press".to_owned()])
        );
        assert_eq!(
            solr_document.publisher_citation_display,
            Some(vec!["Princeton Press".to_owned()])
        );
    }
    #[test]
    fn it_has_the_accepted_vocabulary_from_the_ephemera_folder_item() {
        let ephemera_item = EphemeraFolder::builder()
            .id("abc123".to_owned())
            .title(vec!["Our favorite book".to_owned()])
            .subject(vec![Subject {
                exact_match: ExactMatch {
                    id: "http://id.loc.gov/authorities/subjects/sh85088762".to_owned(),
                },
                label: "Music".to_string(),
            }])
            .build()
            .unwrap();
        assert!(ephemera_item.subject.unwrap()[0]
            .exact_match
            .accepted_vocabulary());
    }
    #[test]
    fn it_includes_subject_terms_in_lc_subject_display_and_lc_subject_facet_field() {
        let ephemera_item = EphemeraFolder::builder()
            .id("abc123".to_owned())
            .title(vec!["Our favorite book".to_owned()])
            .subject(vec![Subject {
                exact_match: ExactMatch {
                    id: "http://id.loc.gov/authorities/subjects/sh85088762".to_owned(),
                },
                label: "Music".to_string(),
            }])
            .build()
            .unwrap();
        let solr_document = SolrDocument::from(&ephemera_item);
        assert_eq!(
            solr_document.lc_subject_display,
            Some(vec!["Music".to_string()])
        );
        assert_eq!(
            solr_document.lc_subject_facet,
            Some(vec!["Music".to_string()])
        );
    }
    #[test]
    fn it_includes_subject_terms_in_homoit_subject_display_and_homoit_subject_facet_field() {
        let ephemera_item = EphemeraFolder::builder()
            .id("abc123".to_owned())
            .title(vec!["Our favorite book".to_owned()])
            .subject(vec![Subject {
                exact_match: ExactMatch {
                    id: "https://homosaurus.org/v4/homoit0000485".to_owned(),
                },
                label: "Gay Community".to_string(),
            }])
            .build()
            .unwrap();
        let solr_document = SolrDocument::from(&ephemera_item);
        assert_eq!(
            solr_document.homoit_subject_display,
            Some(vec!["Gay Community".to_string()])
        );
        assert_eq!(
            solr_document.homoit_subject_facet,
            Some(vec!["Gay Community".to_string()])
        );
    }
    #[test]
    fn it_includes_coverage_labels_in_geographic_facet_field() {
        let ephemera_item = EphemeraFolder::builder()
            .id("abc123".to_owned())
            .title(vec!["Our favorite book".to_owned()])
            .coverage(vec![Coverage {
                exact_match: country::ExactMatch {
                    id: "http://id.loc.gov/vocabulary/countries/an".to_owned(),
                },
                label: "Andorra".to_string(),
            }])
            .build()
            .unwrap();
        let solr_document = SolrDocument::from(&ephemera_item);
        assert_eq!(
            solr_document.geographic_facet,
            Some(vec!["Andorra".to_string()])
        );
    }
    #[test]
    fn it_includes_date_created_in_pub_date_start_sort() {
        let ephemera_item = EphemeraFolder::builder()
            .id("abc123".to_owned())
            .title(vec!["Our favorite book".to_owned()])
            .date_created(vec!["1973-10-01".to_string()])
            .build()
            .unwrap();
        let solr_document = SolrDocument::from(&ephemera_item);
        assert_eq!(solr_document.pub_date_start_sort, Some(1973));
    }
    #[test]
    fn it_concats_page_count_into_description_display() {
        let item = EphemeraFolder::builder()
            .id("12345".to_string())
            .title(vec!["Bohemian Rhapsody".to_string()])
            .page_count("333".to_string())
            .origin_place(vec![OriginPlace {
                exact_match: country::ExactMatch {
                    id: "http://id.loc.gov/vocabulary/countries/ck".to_owned(),
                },
                label: "Colombia".to_string(),
            }])
            .build()
            .unwrap();
        let solr = SolrDocument::from(&item);
        assert_eq!(
            solr.description_display,
            Some(vec!["pages: 333".to_string()])
        );
    }
    #[test]
    fn it_combines_date_created_and_publisher_into_pub_date_display() {
        let item = EphemeraFolder::builder()
            .id("12345".to_string())
            .title(vec!["Bohemian Rhapsody".to_string()])
            .date_created(vec!["1973".to_string()])
            .publisher(vec!["Rolling Press".to_string()])
            .build()
            .unwrap();
        let solr = SolrDocument::from(&item);
        assert_eq!(
            solr.pub_date_display,
            Some(vec!["1973".to_string(), "Rolling Press".to_string()])
        );
    }
    #[test]
    fn it_combines_origin_place_and_publisher_and_date_created_into_pub_citation_display() {
        let item = EphemeraFolder::builder()
            .id("12345".to_string())
            .title(vec!["Bohemian Rhapsody".to_string()])
            .date_created(vec!["1973".to_string()])
            .publisher(vec!["Rolling Press".to_string()])
            .origin_place(vec![OriginPlace {
                exact_match: country::ExactMatch {
                    id: "http://id.loc.gov/vocabulary/countries/ck".to_owned(),
                },
                label: "Colombia".to_string(),
            }])
            .build()
            .unwrap();
        let solr = SolrDocument::from(&item);
        assert_eq!(
            solr.pub_citation_display,
            Some(vec!["Colombia: Rolling Press, 1973".to_string()])
        );
    }
    #[test]
    fn it_has_access_facet_online() {
        let ephemera_item = EphemeraFolder::builder()
            .id("abc123".to_owned())
            .title(vec!["Our favorite book".to_owned()])
            .build()
            .unwrap();
        let solr_document = SolrDocument::from(&ephemera_item);
        assert_eq!(solr_document.access_facet, Some(solr::AccessFacet::Online));
    }
    #[test]
    fn it_has_title_sort() {
        let ephemera_item = EphemeraFolder::builder()
            .id("abc123".to_owned())
            .title(vec!["Our favorite book".to_owned()])
            .sort_title(vec!["The book of trees".to_owned()])
            .build()
            .unwrap();
        let solr_document = SolrDocument::from(&ephemera_item);
        assert_eq!(
            solr_document.title_sort,
            Some("The book of trees".to_string())
        );
    }
    #[test]
    fn it_uses_title_as_title_sort_when_sort_title_is_unavailable() {
        let ephemera_item = EphemeraFolder::builder()
            .id("abc123".to_owned())
            .title(vec!["Our favorite book".to_owned()])
            .build()
            .unwrap();
        let solr_document = SolrDocument::from(&ephemera_item);
        assert_eq!(
            solr_document.title_sort,
            Some("Our favorite book".to_string())
        );
    }
    #[test]
    fn it_has_electronic_access_1display() {
        let ephemera_item = EphemeraFolder::builder()
            .id("abc123".to_owned())
            .title(vec!["Our favorite book".to_owned()])
            .electronic_access(vec![solr::ElectronicAccess {
                url: "http://example.com".to_owned(),
                link_text: "Access Link".to_owned(),
                link_description: Some("Description of the link".to_owned()),
            }])
            .build()
            .unwrap();
        let solr_document = SolrDocument::from(&ephemera_item);
        assert_eq!(
            solr_document.electronic_access_1display,
            Some(solr::ElectronicAccess {
                url: ephemera_item.id.clone(),
                link_text: "Online Content".to_owned(),
                link_description: Some(
                    "Born Digital Monographs, Serials, & Series Reports".to_owned()
                ),
            })
        );
    }
}
