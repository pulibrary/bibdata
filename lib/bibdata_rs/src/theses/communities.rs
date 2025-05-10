use magnus::exception;

fn magnus_err_from_reqwest_err(value: &reqwest::Error) -> magnus::Error {
    magnus::Error::new(exception::runtime_error(), value.to_string())
}

pub fn api_communities_json(server: String) -> Result<String, magnus::Error> {
    reqwest::blocking::get(format!("{}/communities/", server))
        .map_err(|e| magnus_err_from_reqwest_err(&e))?
        .text()
        .map_err(|e| magnus_err_from_reqwest_err(&e))
}
