use crate::{
    ephemera::ephemera_folder::subject::log_subjects_without_exact_match,
    solr::{self, AccessFacet},
};
use serde::{Deserializer, Serialize};

use super::{
    born_digital_collection::ephemera_folders_iterator,
    ephemera_folder_builder::EphemeraFolderBuilder,
};
use log::{debug, trace};
use serde::Deserialize;

pub mod country;
pub mod coverage;
pub mod format;
pub mod language;
pub mod origin_place;
pub mod subject;

use coverage::Coverage;
use format::Format;
use language::Language;
use origin_place::OriginPlace;
use serde_json::Value;
use subject::Subject;

#[derive(Deserialize, Debug)]
pub struct EphemeraFolder {
    pub alternative: Option<Vec<String>>,
    pub creator: Option<Vec<String>>,
    pub contributor: Option<Vec<String>>,
    pub coverage: Option<Vec<Coverage>>,
    pub date_created: Option<Vec<String>>,
    pub description: Option<Vec<String>>,
    pub electronic_access: Option<Vec<solr::ElectronicAccess>>,
    pub format: Option<Vec<Format>>,
    #[serde(rename = "@id")]
    pub id: String,
    pub language: Option<Vec<Language>>,
    #[serde(rename = "origin_place")]
    #[serde(default, deserialize_with = "option_vec_safe_deserialize")]
    pub origin: Option<VecSafe<OriginPlace>>,
    pub page_count: Option<String>,
    pub provenance: Option<String>,
    pub publisher: Option<Vec<String>>,
    #[serde(default, deserialize_with = "option_vec_safe_deserialize")]
    pub subject: Option<VecSafe<Subject>>,
    pub sort_title: Option<Vec<String>>,
    pub thumbnail: Option<Thumbnail>,
    pub title: Vec<String>,
    pub transliterated_title: Option<Vec<String>>,
}

#[derive(Debug, Deserialize, PartialEq, Clone)]
pub struct Thumbnail {
    #[serde(rename = "@id")]
    pub thumbnail_url: String,
}
impl Thumbnail {
    pub fn normalized_url(&self) -> String {
        self.thumbnail_url
            .replace("/full/!200,150/0/default.jpg", "/square/225,/0/default.jpg")
    }
}
#[derive(Debug, Serialize, PartialEq, Clone)]
pub struct AuthorRoles {
    pub secondary_authors: Vec<String>,
    pub translators: Vec<String>,
    pub editors: Vec<String>,
    pub compilers: Vec<String>,
    pub primary_author: String,
}

// VecSafe is a wrapper around Vec<T> that provides safe deserialization from JSON arrays
// containing objects. It ignores any elements that fail to deserialize into T.
#[derive(PartialEq, Debug, Clone)]
pub struct VecSafe<T>(pub Vec<T>);

use std::ops::Deref;

impl<T> Deref for VecSafe<T> {
    type Target = Vec<T>;
    fn deref(&self) -> &Self::Target {
        &self.0
    }
}

pub fn vec_safe_deserialize<'de, D, T>(deserializer: D) -> Result<VecSafe<T>, D::Error>
where
    D: Deserializer<'de>,
    T: serde::de::DeserializeOwned,
{
    let raw = Vec::<serde_json::Value>::deserialize(deserializer)?;
    let mut result = Vec::new();
    for value in raw {
        if let Ok(item) = serde_json::from_value::<T>(value) {
            result.push(item);
        }
    }
    Ok(VecSafe(result))
}

// Custom deserializer for Option<VecSafe<T>>
pub fn option_vec_safe_deserialize<'de, D, T>(
    deserializer: D,
) -> Result<Option<VecSafe<T>>, D::Error>
where
    D: Deserializer<'de>,
    T: serde::de::DeserializeOwned,
{
    // Try to deserialize as Option<Vec<serde_json::Value>>
    let opt_raw = Option::<Vec<serde_json::Value>>::deserialize(deserializer)?;
    match opt_raw {
        Some(raw) => {
            let mut result = Vec::new();
            for value in raw {
                if let Ok(item) = serde_json::from_value::<T>(value) {
                    result.push(item);
                }
            }
            if result.is_empty() {
                Ok(None)
            } else {
                Ok(Some(VecSafe(result)))
            }
        }
        None => Ok(None),
    }
}

impl<'de, T> Deserialize<'de> for VecSafe<T>
where
    T: serde::de::DeserializeOwned,
{
    fn deserialize<D>(deserializer: D) -> Result<Self, D::Error>
    where
        D: Deserializer<'de>,
    {
        vec_safe_deserialize(deserializer)
    }
}

impl EphemeraFolder {
    pub fn builder() -> EphemeraFolderBuilder {
        EphemeraFolderBuilder::new()
    }
    pub fn thumbnail_url(&self) -> Option<String> {
        self.thumbnail.as_ref().map(|t| t.normalized_url().clone())
    }
    pub fn solr_formats(&self) -> Vec<solr::FormatFacet> {
        match &self.format {
            Some(formats) => formats.iter().filter_map(|f| f.pref_label).collect(),
            None => vec![],
        }
    }

    pub fn coverage_labels(&self) -> Vec<String> {
        match &self.coverage {
            Some(coverage_vector) => coverage_vector
                .iter()
                .filter(|coverage| coverage.exact_match.accepted_vocabulary())
                .map(|coverage| coverage.label.clone())
                .collect(),
            None => vec![],
        }
    }

    pub fn origin_place_labels(&self) -> Vec<String> {
        match &self.origin {
            Some(origin_vector) => origin_vector
                .iter()
                .filter(|origin| origin.exact_match.accepted_vocabulary())
                .map(|origin| origin.label.clone())
                .collect(),
            None => vec![],
        }
    }

    pub fn homoit_subject_labels(&self) -> Option<Vec<String>> {
        self.subject.as_ref().map(|subjects| {
            subjects
                .iter()
                .filter(|s| {
                    s.exact_match
                        .as_ref()
                        .map(|em| em.accepted_homoit_vocabulary())
                        .unwrap_or(false)
                })
                .map(|s| s.label.clone())
                .collect()
        })
    }

    pub fn lc_subject_labels(&self) -> Option<Vec<String>> {
        self.subject.as_ref().map(|subjects| {
            subjects
                .iter()
                .filter(|s| {
                    s.exact_match
                        .as_ref()
                        .map(|em| em.accepted_loc_vocabulary())
                        .unwrap_or(false)
                })
                .map(|s| s.label.clone())
                .collect()
        })
    }

    pub fn language_labels(&self) -> Vec<String> {
        match &self.language {
            Some(languages) => languages.iter().map(|l| l.label.clone()).collect(),
            None => vec![],
        }
    }
    pub fn group_contributors(&self) -> Option<String> {
        let primary_author = self
            .creator
            .as_ref()
            .and_then(|v| v.first())
            .cloned()
            .unwrap_or_default();
        let secondary_authors = self.contributor.clone().unwrap_or_default();
        if primary_author.is_empty() && secondary_authors.is_empty() {
            return None;
        }

        let roles = AuthorRoles {
            secondary_authors,
            translators: vec![],
            editors: vec![],
            compilers: vec![],
            primary_author,
        };

        serde_json::to_string(&roles).ok()
    }

    pub fn all_contributors(&self) -> Vec<String> {
        let mut all_contributors = Vec::default();
        all_contributors.extend(self.creator.clone().unwrap_or_default());
        all_contributors.extend(self.contributor.clone().unwrap_or_default());
        all_contributors
    }

    pub fn date_created_year(&self) -> Option<i16> {
        self.date_created
            .as_ref()?
            .iter()
            .find_map(|date_str| date_str.get(0..4)?.parse::<i16>().ok())
    }

    pub fn other_title_display_combined(&self) -> Vec<String> {
        let mut combined = self.alternative.clone().unwrap_or_default();
        combined.extend(self.transliterated_title.clone().unwrap_or_default());
        combined
    }

    pub fn concat_page_count(&self) -> Vec<String> {
        match self.page_count.clone() {
            Some(page_count) => vec![format!("pages: {}", page_count)],
            None => Vec::new(),
        }
    }

    pub fn date_created_publisher_combined(&self) -> Vec<String> {
        let mut combined = self.date_created.clone().unwrap_or_default();
        combined.extend(self.publisher.clone().unwrap_or_default());
        combined
    }

    pub fn origin_place_publisher_date_created_combined(&self) -> Vec<String> {
        let origin = self
            .origin_place_labels()
            .first()
            .cloned()
            .unwrap_or_default();
        let publisher = self
            .publisher
            .clone()
            .unwrap_or_default()
            .first()
            .cloned()
            .unwrap_or_default();
        let date = self
            .date_created
            .clone()
            .unwrap_or_default()
            .first()
            .cloned()
            .unwrap_or_default();
        let mut result = Vec::new();
        if !origin.is_empty() || !publisher.is_empty() || !date.is_empty() {
            let mut s = String::new();
            if !origin.is_empty() {
                s.push_str(&origin);
            }
            if !publisher.is_empty() {
                if !s.is_empty() {
                    s.push_str(": ");
                }
                s.push_str(&publisher);
            }
            if !date.is_empty() {
                if !s.is_empty() {
                    s.push_str(", ");
                }
                s.push_str(&date);
            }
            result.push(s);
        }
        result
    }
    pub fn first_sort_title(&self) -> Option<String> {
        self.sort_title
            .as_ref()
            .or(Some(&self.title))?
            .first()
            .cloned()
    }
    pub fn access_facet(&self) -> Option<AccessFacet> {
        Some(AccessFacet::Online)
    }
    pub async fn fetch_thumbnail(
        &self,
        domain: &str,
        id: &str,
    ) -> Result<Option<Thumbnail>, anyhow::Error> {
        let manifest_url = format!("{domain}/concern/ephemera_folders/{}/manifest", id);
        debug!("Fetching manifest from {manifest_url}");
        let resp = reqwest::get(&manifest_url).await?.text().await?;
        let manifest: Value = serde_json::from_str(&resp)?;
        if let Some(thumbnail_json) = manifest.get("thumbnail") {
            let thumbnail: Thumbnail = serde_json::from_value(thumbnail_json.clone())?;
            Ok(Some(thumbnail))
        } else {
            Ok(None)
        }
    }
    pub fn electronic_access(&self) -> Option<solr::ElectronicAccess> {
        Some(solr::ElectronicAccess {
            url: format!(
                "https://catalog-staging.princeton.edu/catalog/{}#view",
                self.normalized_id()
            ),
            link_text: "Digital content".to_owned(),
            link_description: None,
            iiif_manifest_paths: Some(format!(
                "https://figgy.princeton.edu/concern/ephemera_folders/{}/manifest",
                self.normalized_id()
            )),
        })
    }
    pub fn normalized_id(&self) -> String {
        self.id
            .split('/')
            .next_back()
            .unwrap_or(&self.id)
            .trim()
            .to_string()
    }
}

#[allow(dead_code)]
#[derive(Deserialize, Debug)]
pub struct ItemResponse {
    pub data: Vec<EphemeraFolder>,
}

pub fn json_ephemera_document(url: String) -> Result<String, magnus::Error> {
    #[cfg(not(test))]
    let _ = env_logger::try_init();
    let rt = tokio::runtime::Runtime::new()
        .map_err(|e| magnus::Error::new(magnus::exception::runtime_error(), e.to_string()))?;
    rt.block_on(async {
        let folder_results = ephemera_folders_iterator(&url, 1_000)
            .await
            .map_err(|e| magnus::Error::new(magnus::exception::runtime_error(), e.to_string()))?;

        for folder_json in &folder_results {
            if let Ok(folder) = serde_json::from_str::<EphemeraFolder>(folder_json) {
                if let Some(subjects) = &folder.subject {
                    log_subjects_without_exact_match(subjects);
                }
            }
        }

        let combined_json = folder_results.join(",");
        trace!("The JSON that we will post to Solr is {}", combined_json);
        Ok(combined_json)
    })
}

#[cfg(test)]
mod tests {
    use crate::{
        ephemera::{ephemera_folder::country::ExactMatch, CatalogClient},
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

        let ephemera_folder_item: EphemeraFolder = serde_json::from_reader(reader).unwrap();
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
                .mock("GET", "/catalog.json?f%5Bephemera_project_ssim%5D%5B%5D=Born+Digital+Monographic+Reports+and+Papers&f%5Bhuman_readable_type_ssim%5D%5B%5D=Ephemera+Folder&f%5Bstate_ssim%5D%5B%5D=complete&per_page=100&q=")
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
                .mock("GET", "/catalog.json?f%5Bephemera_project_ssim%5D%5B%5D=Born+Digital+Monographic+Reports+and+Papers&f%5Bhuman_readable_type_ssim%5D%5B%5D=Ephemera+Folder&f%5Bstate_ssim%5D%5B%5D=complete&per_page=100&q=")
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
    fn it_can_return_coverage_labels_for_authorized_vocabularies() {
        let item = EphemeraFolder::builder()
            .id("123ABC".to_string())
            .title(vec!["The worst book ever!".to_string()])
            .coverage(vec![
                Coverage {
                    exact_match: ExactMatch {
                        id: "http://id.loc.gov/vocabulary/countries/an".to_string(),
                    },
                    label: "Andorra".to_string(),
                },
                Coverage {
                    exact_match: ExactMatch {
                        id: "http://bad-bad-bad".to_string(),
                    },
                    label: "Anguilla".to_string(),
                },
            ])
            .build()
            .unwrap();
        assert_eq!(item.coverage_labels(), vec!["Andorra".to_string()]);
    }
    #[tokio::test]
    async fn it_can_fetch_thumbnail() {
        let folder = EphemeraFolder::builder()
            .id("fa30780e-dfd8-4545-b1b0-b3eec9fca96b".to_string())
            .title(vec!["The worst book ever!".to_string()])
            .build()
            .unwrap();
        let mut server = mockito::Server::new_async().await;

        let mock = server
            .mock(
                "GET",
                "/concern/ephemera_folders/fa30780e-dfd8-4545-b1b0-b3eec9fca96b/manifest",
            )
            .with_status(200)
            .with_header("content-type", "application/json")
            .with_body_from_file("../../spec/fixtures/files/ephemera/ephemera_manifest.json")
            .create_async()
            .await;
        let result = folder
            .fetch_thumbnail(&server.url(), &folder.id)
            .await
            .unwrap()
            .unwrap();
        mock.assert_async().await;

        assert_eq!(result.thumbnail_url, "https://iiif-cloud.princeton.edu/iiif/2/c9%2Fa6%2F2b%2Fc9a62b81f8014b13933f4cf462c092dc%2Fintermediate_file/full/!200,150/0/default.jpg".to_string());
    }

    #[test]
    fn it_does_not_error_on_invalid_origin_place_type() {
        use serde_json::json;

        let invalid_json = json!({
            "@id": "test-id",
            "title": ["Test Title"],
            "origin_place": [""]
        });

        let result: Result<EphemeraFolder, _> = serde_json::from_value(invalid_json);

        assert!(
            result.is_ok(),
            "Deserialization should not error on invalid origin_place type"
        );
        let folder = result.unwrap();
        assert!(folder.origin.is_none());
    }

    #[test]
    fn it_does_not_error_on_invalid_subject_type() {
        use serde_json::json;

        let invalid_json = json!({
            "@id": "test-id",
            "title": ["Test Title"],
            "subject": ["εφήμερα","θέμα με λάθος δομή"]
        });

        let result: Result<EphemeraFolder, _> = serde_json::from_value(invalid_json);

        assert!(
            result.is_ok(),
            "Deserialization should not error on invalid subject type"
        );
        let folder = result.unwrap();
        assert!(folder.subject.is_none());
    }
}
