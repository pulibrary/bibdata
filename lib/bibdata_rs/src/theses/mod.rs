use std::env;

pub mod config;
pub mod dataspace;
pub mod dataspace_solr_mapping;
pub mod department;
pub mod embargo;
pub mod holdings;
pub mod language;
pub mod latex;
pub mod program;
pub mod restrictions;
pub mod solr;

pub fn theses_cache_path() -> String {
    env::var("FILEPATH").unwrap_or("/tmp/theses.json".to_owned())
}

pub fn looks_like_yes(possible: Option<Vec<String>>) -> bool {
    match possible {
        Some(vec) => vec.first().map_or("", |v| v) == "yes",
        None => false,
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::testing_support::preserving_envvar;

    #[test]
    fn it_determines_the_path_to_cache_the_theses() {
        preserving_envvar("FILEPATH", || {
            env::set_var("FILEPATH", "/home/user/theses.json");
            assert_eq!(theses_cache_path(), "/home/user/theses.json");
        });
    }

    #[test]
    fn it_defaults_theses_cache_path_to_tmp() {
        preserving_envvar("FILEPATH", || {
            env::remove_var("FILEPATH");
            assert_eq!(theses_cache_path(), "/tmp/theses.json");
        });
    }
}
