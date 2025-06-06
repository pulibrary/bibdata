use crate::solr;

use super::{
    ephemera_folder_item_builder::EphemeraFolderItemBuilder,
    ephemera_folders::ephemera_folders_iterator,
};
use log::trace;
use serde::Deserialize;

pub mod country;
pub mod format;
pub mod language;
pub mod subject;

use country::Country;
use format::Format;
use language::Language;
use subject::Subject;

#[derive(Deserialize, Debug)]
pub struct EphemeraFolderItem {
    pub alternative: Option<Vec<String>>,
    pub creator: Option<Vec<String>>,
    pub contributor: Option<Vec<String>>,
    pub country: Option<Vec<Country>>,
    pub description: Option<Vec<String>>,
    pub format: Option<Vec<Format>>,
    #[serde(rename = "@id")]
    pub id: String,
    pub language: Option<Vec<Language>>,
    pub provenance: Option<String>,
    pub publisher: Option<Vec<String>>,
    pub subject: Option<Vec<Subject>>,
    pub title: Vec<String>,
    pub transliterated_title: Option<Vec<String>>,
}

impl EphemeraFolderItem {
    pub fn builder() -> EphemeraFolderItemBuilder {
        EphemeraFolderItemBuilder::new()
    }

    pub fn solr_formats(&self) -> Vec<solr::FormatFacet> {
        match &self.format {
            Some(formats) => formats.iter().filter_map(|f| f.pref_label).collect(),
            None => vec![],
        }
    }

    pub fn country_labels(&self) -> Vec<String> {
        match &self.country {
            Some(countries) => countries
                .iter()
                .filter(|country| country.exact_match.accepted_vocabulary())
                .map(|country| country.label.clone())
                .collect(),
            None => vec![],
        }
    }

    pub fn subject_labels(&self) -> Vec<String> {
        match &self.subject {
            Some(subjects) => subjects.iter().map(|s| s.label.clone()).collect(),
            None => vec![],
        }
    }

    pub fn language_labels(&self) -> Vec<String> {
        match &self.language {
            Some(languages) => languages.iter().map(|l| l.label.clone()).collect(),
            None => vec![],
        }
    }

    pub fn all_contributors(&self) -> Vec<String> {
        let mut all_contributors = Vec::default();
        all_contributors.extend(self.creator.clone().unwrap_or_default());
        all_contributors.extend(self.contributor.clone().unwrap_or_default());
        all_contributors
    }

    pub fn first_contibutor(&self) -> Option<String> {
        self.all_contributors().first().cloned()
    }
}

#[allow(dead_code)]
#[derive(Deserialize, Debug)]
pub struct ItemResponse {
    pub data: Vec<EphemeraFolderItem>,
}

impl EphemeraFolderItem {
    pub fn other_title_display_combined(&self) -> Vec<String> {
        let mut combined = self.alternative.clone().unwrap_or_default();
        combined.extend(self.transliterated_title.clone().unwrap_or_default());
        combined
    }
}

pub fn json_ephemera_document(url: String) -> Result<String, magnus::Error> {
    #[cfg(not(test))]
    env_logger::init();
    let rt = tokio::runtime::Runtime::new()
        .map_err(|e| magnus::Error::new(magnus::exception::runtime_error(), e.to_string()))?;
    rt.block_on(async {
        let folder_results = ephemera_folders_iterator(&url, 1_000)
            .await
            .map_err(|e| magnus::Error::new(magnus::exception::runtime_error(), e.to_string()))?;
        let combined_json = folder_results.join(",");
        trace!("The JSON that we will post to Solr is {}", combined_json);
        Ok(combined_json)
    })
}

#[cfg(test)]
mod tests {
    use crate::{
        ephemera::{ephemera_folder_item::country::ExactMatch, CatalogClient},
        solr,
        testing_support::{preserving_envvar, preserving_envvar_async},
    };

    use super::*;
    use std::fs::File;
    use std::io::BufReader;

    #[tokio::test]
    async fn test_get_item_data() {
        preserving_envvar_async("FIGGY_BORN_DIGITAL_EPHEMERA_URL", || async {
            let mut server = mockito::Server::new_async().await;
            std::env::set_var("FIGGY_BORN_DIGITAL_EPHEMERA_URL", server.url());

            let mock = server
                .mock(
                    "GET",
                    "/catalog/af4a941d-96a4-463e-9043-cfa512e5eddd.jsonld",
                )
                .with_status(200)
                .with_header("content-type", "application/json")
                .with_body_from_file("../../spec/fixtures/files/ephemera/ephemera1.json")
                .create_async()
                .await;

            let client = CatalogClient::new(server.url());
            let result = client
                .get_item_data("af4a941d-96a4-463e-9043-cfa512e5eddd")
                .await;

            mock.assert_async().await;

            match result {
                Ok(_response) => assert!(true),
                Err(e) => panic!("Request failed: {}", e),
            }
        })
        .await
    }

    #[test]
    fn it_can_read_the_format_from_json_ld() {
        let file = File::open("../../spec/fixtures/files/ephemera/ephemera1.json").unwrap();
        let reader = BufReader::new(file);

        let ephemera_folder_item: EphemeraFolderItem = serde_json::from_reader(reader).unwrap();
        assert_eq!(
            ephemera_folder_item.format.unwrap()[0].pref_label,
            Some(solr::FormatFacet::Book)
        );
    }

    #[test]
    fn test_json_ephemera_document() {
        preserving_envvar("FIGGY_BORN_DIGITAL_EPHEMERA_URL", || {
            let mut server = mockito::Server::new();

            let folder_mock = server
                .mock("GET", "/catalog.json?f%5Bephemera_project_ssim%5D%5B%5D=Born+Digital+Monographs%2C+Serials%2C+%26+Series+Reports&f%5Bhuman_readable_type_ssim%5D%5B%5D=Ephemera+Folder&f%5Bstate_ssim%5D%5B%5D=complete&per_page=100&q=")
                .with_status(200)
                .with_header("content-type", "application/json")
                .with_body_from_file("../../spec/fixtures/files/ephemera/ephemera_folders.json")
                .create();

            let item_mock = server
                .mock(
                    "GET",
                    mockito::Matcher::Regex(
                        r"^/catalog/[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}.jsonld$"
                            .to_string(),
                    ),
                )
                .with_status(200)
                .with_header("content-type", "application/json")
                .with_body_from_file("../../spec/fixtures/files/ephemera/ephemera1.json")
                .expect(12)
                .create();

            let result = json_ephemera_document(server.url().to_string()).unwrap();

            let parsed: serde_json::Value = serde_json::from_str(&result).unwrap();
            assert!(parsed.is_array());

            folder_mock.assert();
            item_mock.assert();
        });
    }

    mod no_transliterated_title {

        use rb_sys_test_helpers::ruby_test;

        use super::*;
        #[ruby_test]
        fn test_json_ephemera_document_with_no_transliterated_title() {
            let mut server = mockito::Server::new();

            let folder_mock = server
                .mock("GET", "/catalog.json?f%5Bephemera_project_ssim%5D%5B%5D=Born+Digital+Monographs%2C+Serials%2C+%26+Series+Reports&f%5Bhuman_readable_type_ssim%5D%5B%5D=Ephemera+Folder&f%5Bstate_ssim%5D%5B%5D=complete&per_page=100&q=")
                .with_status(200)
                .with_header("content-type", "application/json")
                .with_body_from_file("../../spec/fixtures/files/ephemera/ephemera_folders.json")
                .create();

            let item_mock = server
                .mock(
                    "GET",
                    mockito::Matcher::Regex(
                        r"^/catalog/[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}.jsonld$"
                            .to_string(),
                    ),
                )
                .with_status(200)
                .with_header("content-type", "application/json")
                .with_body_from_file(
                    "../../spec/fixtures/files/ephemera/ephemera_no_transliterated_title.json",
                )
                .expect(12)
                .create();

            let result = json_ephemera_document(server.url().to_string()).unwrap();
            let parsed: serde_json::Value = serde_json::from_str(&result).unwrap();
            assert!(parsed.is_array());
            folder_mock.assert();
            item_mock.assert();
        }
    }

    #[test]
    fn it_can_return_country_labels_for_authorized_vocabularies() {
        let item = EphemeraFolderItem::builder()
            .id("123ABC".to_string())
            .title(vec!["The worst book ever!".to_string()])
            .country(vec![
                Country {
                    exact_match: ExactMatch {
                        id: country::Id {
                            id: "[\"http://id.loc.gov/vocabulary/countries/an\"]".to_string(),
                        },
                    },
                    label: "Andorra".to_string(),
                },
                Country {
                    exact_match: ExactMatch {
                        id: country::Id {
                            id: "[\"http://bad-bad-bad\"]".to_string(),
                        },
                    },
                    label: "Anguilla".to_string(),
                },
            ])
            .build()
            .unwrap();
        assert_eq!(item.country_labels(), vec!["Andorra".to_string()]);
    }
}
