use anyhow::anyhow;
use born_digital_collection::FoldersResponse;
use ephemera_folder::EphemeraFolder;
use log::debug;

pub mod born_digital_collection;
pub mod ephemera_folder;
mod ephemera_folder_builder;

pub struct CatalogClient {
    url: String,
}

impl Default for CatalogClient {
    fn default() -> Self {
        Self::new(std::env::var("FIGGY_URL").unwrap_or("https://figgy.princeton.edu".to_string()))
    }
}

impl CatalogClient {
    pub fn new(url: String) -> Self {
        CatalogClient { url }
    }
    pub async fn get_folder_data(&self) -> anyhow::Result<FoldersResponse> {
        let path = std::env::var("FIGGY_BORN_DIGITAL_EPHEMERA_URL").unwrap_or("/catalog.json?f%5Bephemera_project_ssim%5D%5B%5D=Born+Digital+Monographs%2C+Serials%2C+%26+Series+Reports&f%5Bhuman_readable_type_ssim%5D%5B%5D=Ephemera+Folder&f%5Bstate_ssim%5D%5B%5D=complete&per_page=100&q=".to_string());
        let url = format!("{}{}", &self.url, path);
        debug!("Fetching JSON-LD of folders at {}", url);
        let response = reqwest::get(url).await?;
        let data: FoldersResponse = response
            .json()
            .await
            .map_err(|err| anyhow!("Could not parse born digital search results: {err:?}"))?;
        Ok(data)
    }

    pub async fn get_item_data(&self, id: &str) -> anyhow::Result<EphemeraFolder> {
        let url = format!("{}/catalog/{}.jsonld", &self.url, id);
        debug!("Fetching JSON-LD of a single folder at {}", url);
        let response = reqwest::get(&url).await?;
        let data: EphemeraFolder = response
            .json()
            .await
            .map_err(|err| anyhow!("Could not parse ephemera folder JSON at {url}: {err:?}"))?;
        Ok(data)
    }
}
