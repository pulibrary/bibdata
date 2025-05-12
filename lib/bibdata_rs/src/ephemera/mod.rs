use ephemera_folder::FolderResponse;
use ephemera_item::{EphemeraItem, ItemResponse};

pub mod ephemera_folder;
pub mod ephemera_item;

pub struct CatalogClient {
    url: String,
}

impl Default for CatalogClient {
    fn default() -> Self {
        Self::new()
    }
}

impl CatalogClient {
    pub fn new() -> Self {
        let figgy_ephemera_url = std::env::var("FIGGY_BORN_DIGITAL_EPHEMERA_URL");
        CatalogClient {
            url: figgy_ephemera_url.unwrap(),
        }
    }
    pub async fn get_folder_data(&self) -> Result<FolderResponse, reqwest::Error> {
        let response = reqwest::get(&self.url).await?;
        let data: FolderResponse = response.json().await?;
        Ok(data)
    }

    pub async fn get_item_data(&self) -> Result<EphemeraItem, reqwest::Error> {
        let response = reqwest::get(&self.url).await?;
        let data: EphemeraItem = response.json().await?;
        Ok(data)
    }
}
