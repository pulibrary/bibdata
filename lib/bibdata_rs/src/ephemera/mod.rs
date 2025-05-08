mod ephemera_folder;
mod ephemera_item;

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
}
