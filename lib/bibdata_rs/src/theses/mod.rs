use serde::{ser::SerializeStruct, Deserialize, Serialize, Serializer};
use std::{fs, env};

pub mod department;
pub mod latex;
pub mod program;

#[derive(Deserialize)]
struct Metadata {
    #[serde(rename = "oai_dc:dc")]
    thesis: Thesis,
}

#[derive(Debug, Deserialize)]
struct Thesis {
    #[serde(rename = "dc:title")]
    title: Vec<String>,
}

impl Serialize for Thesis {
    fn serialize<S>(&self, serializer: S) -> Result<S::Ok, S::Error>
    where
        S: Serializer,
    {
        let mut serializer = serializer.serialize_struct("Document", 1)?;
        serializer.serialize_field("title_citation_display", &self.title.first())?;
        serializer.serialize_field("title_display", &self.title.first())?;
        serializer.serialize_field("format", "Senior Thesis")?;
        serializer.end()
    }
}

pub fn json_document(path: String) -> String {
    let data = fs::read_to_string(path).expect("Unable to read file");
    let metadata: Metadata = serde_xml_rs::SerdeXml::new()
        .namespace("oai_dc", "http://www.openarchives.org/OAI/2.0/oai_dc/")
        .namespace("dc", "http://purl.org/dc/elements/1.1/")
        .from_str(&data)
        .expect("Unable to parse XML");
    serde_json::to_string(&metadata.thesis).unwrap()
}

pub fn theses_cache_path() -> String {
    env::var("FILEPATH").unwrap_or("/tmp/theses.json".to_owned())
}

pub fn rails_env() -> String {
    env::var("RAILS_ENV").unwrap_or("development".to_owned())
}

#[cfg(test)]
mod tests {
    use std::sync::Mutex;

    use super::*;

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

    #[test]
    fn it_determines_the_rails_env() {
        preserving_envvar("RAILS_ENV", || {
            env::set_var("RAILS_ENV", "production");
            assert_eq!(rails_env(), "production");
        });
    }

    #[test]
    fn it_defaults_the_rails_env_to_development() {
        preserving_envvar("RAILS_ENV", || {
            env::remove_var("RAILS_ENV");
            assert_eq!(rails_env(), "development");
        });
    }

    lazy_static::lazy_static! {
        static ref ENV_MUTEX: Mutex<()> = Mutex::new(());
    }

    fn preserving_envvar<T: Fn() -> ()>(key: &str, f: T) {
        let _lock = ENV_MUTEX.lock().unwrap(); // Ensure exclusive access to environment variables
        let original = match env::var(key) {
            Ok(value) => Some(value),
            Err(_) => None,
        };
        f();
        if let Some(value) = original {
            env::set_var(key, value);
        } else {
            env::remove_var(key);
        }
    }
}

