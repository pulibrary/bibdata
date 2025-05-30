use crate::ephemera::ephemera_item::EphemeraItem;

use super::SolrDocument;

impl From<&EphemeraItem> for SolrDocument {
    fn from(value: &EphemeraItem) -> Self {
        SolrDocument::builder()
            .with_title_citation_display(value.title.first().cloned())
            .with_other_title_display(Some(value.other_title_display()))
            .build()
    }
}

#[cfg(test)]
mod tests {
    use std::{fs::File, io::BufReader};

    use super::*;

    #[test]
    fn it_has_alternative_title_display() {
        let document = EphemeraItem::builder()
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
        let item = EphemeraItem::builder()
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
        let ephemera_item: EphemeraItem = serde_json::from_reader(reader).unwrap();
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
}
