use crate::ephemera::ephemera_folder_item::EphemeraFolderItem;

use super::SolrDocument;

impl From<&EphemeraFolderItem> for SolrDocument {
    fn from(value: &EphemeraFolderItem) -> Self {
        SolrDocument::builder()
            .with_title_citation_display(value.title.first().cloned())
            .with_other_title_display(Some(value.other_title_display_combined()))
            .with_id(value.id.clone())
            .with_author_display(value.creator.clone())
            .with_author_s(value.creator.clone().unwrap_or_default())
            .with_author_sort(value.creator.clone().unwrap_or_default().first().cloned())
            .with_author_roles_1display(value.creator.clone().unwrap_or_default().first().cloned())
            .with_author_citation_display(value.creator.clone())
            .with_notes(value.description.clone())
            .with_notes_display(value.description.clone())
            .with_format(value.solr_formats())
            .with_pub_created_display(value.publisher.clone())
            .with_publisher_no_display(value.publisher.clone())
            .with_publisher_citation_display(value.publisher.clone())
            .build()
    }
}

#[cfg(test)]
mod tests {
    use std::{fs::File, io::BufReader, str::FromStr};

    use crate::{ephemera::ephemera_folder_item::format::Format, solr};

    use super::*;

    #[test]
    fn it_has_alternative_title_display() {
        let document = EphemeraFolderItem::builder()
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
        let item = EphemeraFolderItem::builder()
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
        let ephemera_item: EphemeraFolderItem = serde_json::from_reader(reader).unwrap();
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
    }

    #[test]
    fn it_has_the_id_from_the_ephemera_folder_item() {
        let ephemera_item = EphemeraFolderItem::builder()
            .id("abc123".to_owned())
            .title(vec!["Our favorite book".to_owned()])
            .build()
            .unwrap();
        let solr_document = SolrDocument::from(&ephemera_item);
        assert_eq!(solr_document.id, "abc123");
    }

    #[test]
    fn it_has_the_description_from_the_ephemera_folder_item() {
        let ephemera_item = EphemeraFolderItem::builder()
            .id("abc123".to_owned())
            .title(vec!["Our favorite book".to_owned()])
            .description(vec!["Puppy biting".to_owned()])
            .build()
            .unwrap();
        let solr_document = SolrDocument::from(&ephemera_item);
        assert_eq!(solr_document.notes, Some(vec!["Puppy biting".to_owned()]));
        assert_eq!(
            solr_document.notes_display,
            Some(vec!["Puppy biting".to_owned()])
        );
    }

    #[test]
    fn it_has_the_creator_from_the_ephemera_folder_item() {
        let ephemera_item = EphemeraFolderItem::builder()
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
    fn it_has_the_format_from_the_ephemera_folder_item() {
        let ephemera_item = EphemeraFolderItem::builder()
            .id("abc123".to_owned())
            .title(vec!["Our favorite book".to_owned()])
            .format(vec![Format {
                pref_label: Some(solr::Format::from_str("Serials").unwrap()),
            }])
            .build()
            .unwrap();
        let solr_document = SolrDocument::from(&ephemera_item);
        assert_eq!(solr_document.format, Some(vec![solr::Format::Journal]))
    }

    fn it_has_the_publisher_from_the_ephemera_folder_item() {
        let ephemera_item = EphemeraFolderItem::builder()
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
}
