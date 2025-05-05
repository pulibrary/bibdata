
use serde::Deserialize;

#[derive(Deserialize, Debug)]
pub struct Response {
    pub data: Vec<Item>,
}

#[derive(Deserialize, Debug)]
pub struct Item {
    pub id: String,
    pub attributes: Attributes,
}

#[derive(Deserialize, Debug)]
pub struct Attributes {
    pub title: String,
}

pub struct CatalogClient {
    pub url: String,
}

impl CatalogClient {
    pub fn new() -> Self {
        CatalogClient {
            url: "https://figgy-staging.princeton.edu/catalog.json?f%5Bephemera_project_ssim%5D%5B%5D=Born+Digital+Monographs%2C+Serials%2C+%26+Series+Reports&f%5Bhuman_readable_type_ssim%5D%5B%5D=Ephemera+Folder&f%5Bstate_ssim%5D%5B%5D=complete&per_page=100&q=".to_string(),
        }
    }

    pub async fn get_data(&self) -> Result<Response, reqwest::Error> {
        let response = reqwest::get(&self.url).await?;
        let data: Response = response.json().await?;
        Ok(data)
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[tokio::test]
    async fn test_get_data() {
        let client = CatalogClient::new();
        let result = client.get_data().await;
        assert!(result.is_ok());
    }
}