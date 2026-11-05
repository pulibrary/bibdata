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
    pub async fn get_folder_data(&self, page: u32) -> anyhow::Result<FoldersResponse> {
        let path_template = std::env::var("FIGGY_BORN_DIGITAL_EPHEMERA_URL").unwrap_or("/catalog.json?f%5Bephemera_project_ssim%5D%5B%5D=Born+Digital+Monographic+Reports+and+Papers&f%5Bhuman_readable_type_ssim%5D%5B%5D=Ephemera+Folder&f%5Bstate_ssim%5D%5B%5D=complete&per_page=100&page={page}&q=".to_string());
        let path = path_template.replace("{page}", &page.to_string());
        let url = format!("{}{}", self.url, path);

        debug!("Fetching JSON-LD of folders at {}", url);
        let response = reqwest::get(url).await?;
        let data: FoldersResponse = response
            .json()
            .await
            .map_err(|err| anyhow!("Could not parse born digital search results: {err:?}"))?;
        Ok(data)
    }

    pub async fn get_item_data(&self, id: &str) -> anyhow::Result<EphemeraFolder> {
        let url = format!("{}/catalog/{}.jsonld", self.url, id);
        debug!("Fetching JSON-LD of a single folder at {}", url);
        let response = self.request_with_retries(&url, 3).await?;
        let status = response.status();
        let data: EphemeraFolder = response.json().await.map_err(|err| {
            anyhow!("Could not parse ephemera folder JSON at {url}: {err:?}, status_code: {status}")
        })?;
        Ok(data)
    }

    async fn request_with_retries(
        &self,
        url: &str,
        mut number_of_retries: usize,
    ) -> Result<reqwest::Response, anyhow::Error> {
        while number_of_retries > 0 {
            let response = self
                .figgy_http_client()
                .get(url)
                .send()
                .await
                .expect("Could not send request to Figgy");
            let status = response.status();
            if status == 200 {
                return Ok(response);
            } else {
                number_of_retries -= 1;
            }
        }
        Err(anyhow!(
            "Retried this figgy request several times, giving up"
        ))
    }

    fn figgy_http_client(&self) -> reqwest::Client {
        reqwest::Client::new()
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[tokio::test]
    async fn it_retries_getting_the_item_data_if_it_gets_a_406() {
        let mut server = mockito::Server::new_async().await;

        let failing_request = server
            .mock("GET", "/catalog/123.jsonld")
            .with_status(406)
            .create_async()
            .await;
        let successful_request = server
            .mock("GET", "/catalog/123.jsonld")
            .with_status(200)
            .with_body("{}")
            .create_async()
            .await;

        let _ = CatalogClient::new(server.url()).get_item_data("123").await;

        failing_request.assert_async().await;
        successful_request.assert_async().await;
    }
}
