pub fn collection_url(server: String, id: String, rest_limit: String, offset: String) -> String {
    format!(
        "{}/collections/{}/items?limit={}&offset={}&expand=metadata",
        server, id, rest_limit, offset
    )
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn it_creates_a_collection_url() {
        assert_eq!(collection_url(
            "https://dataspace-dev.princeton.edu/rest".to_owned(),
            "402".to_owned(),
            "100".to_owned(),
            "1000".to_owned()
        ),
    "https://dataspace-dev.princeton.edu/rest/collections/402/items?limit=100&offset=1000&expand=metadata")
    }
}
