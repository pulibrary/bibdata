pub fn restrictions_access(location: Option<String>, access_rights: Option<String>) -> Vec<String> {
    let mut values = vec![location, access_rights];
    values.retain(|value| value.is_some());
    values
        .iter()
        .map(|value| value.clone().unwrap())
        .collect::<Vec<String>>()
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_restrictions_access() {
        let location: Option<String> = None;
        let access_rights = Some("Walk-in Access. This thesis can only be viewed on computer terminals at the <a href=http://mudd.princeton.edu>Mudd Manuscript Library</a>.".to_string());
        assert_eq!(
            restrictions_access(location, access_rights),
            vec!["Walk-in Access. This thesis can only be viewed on computer terminals at the <a href=http://mudd.princeton.edu>Mudd Manuscript Library</a>.".to_string()]
        );
    }

    #[test]
    fn test_restrictions_access_with_none_values() {
        let location: Option<String> = None;
        let access_rights: Option<String> = None;
        assert_eq!(
            restrictions_access(location, access_rights),
            Vec::<String>::new()
        );
    }
}
