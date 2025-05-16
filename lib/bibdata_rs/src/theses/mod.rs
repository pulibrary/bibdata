use std::env;

pub mod dataspace;

mod config;
mod department;
mod embargo;
mod holdings;
mod language;
mod program;
mod solr;

pub fn theses_cache_path() -> String {
    env::var("FILEPATH").unwrap_or("/tmp/theses.json".to_owned())
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
