use ephemera_folder::FolderResponse;
use ephemera_item::EphemeraItem;
use log::debug;

pub mod ephemera_folder;
pub mod ephemera_item;
mod ephemera_item_builder;

pub struct CatalogClient {
    url: String,
}

impl Default for CatalogClient {
    fn default() -> Self {
        Self::new(
            std::env::var("FIGGY_PRODUCTION").unwrap_or("https://figgy.princeton.edu".to_string()),
        )
    }
}

impl CatalogClient {
    pub fn new(url: String) -> Self {
        CatalogClient { url }
    }
    pub async fn get_folder_data(&self) -> Result<FolderResponse, reqwest::Error> {
        let path = std::env::var("FIGGY_BORN_DIGITAL_EPHEMERA_URL").unwrap_or("/catalog.json?f%5Bephemera_project_ssim%5D%5B%5D=Born+Digital+Monographs%2C+Serials%2C+%26+Series+Reports&f%5Bhuman_readable_type_ssim%5D%5B%5D=Ephemera+Folder&f%5Bstate_ssim%5D%5B%5D=complete&per_page=100&q=".to_string());
        let url = format!("{}{}", &self.url, path);
        debug!("Fetching JSON-LD of folders at {}", url);
        let response = reqwest::get(url).await?;
        let data: FolderResponse = response.json().await?;
        Ok(data)
    }

    pub async fn get_item_data(&self, id: &str) -> Result<EphemeraItem, reqwest::Error> {
        let url = format!("{}/catalog/{}.jsonld", &self.url, id);
        debug!("Fetching JSON-LD of a single folder at {}", url);
        let response = reqwest::get(url).await?;
        let data: EphemeraItem = response.json().await?;
        Ok(data)
    }
}
