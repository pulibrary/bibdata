use serde_json::Value;
use std::env;
use std::fs;
use uuid::Uuid;

pub fn cluster_id(id: String) -> String {
    let file_path = env::var("CLUSTER_JSON_PATH")
        .unwrap_or_else(|_| "cluster/data/clusters_with_uuid.json".to_string());

    if let Ok(json_content) = fs::read_to_string(file_path) {
        if let Ok(json_data) = serde_json::from_str::<Value>(&json_content) {
            if let Some(clusters) = json_data["clusters"].as_array() {
                for cluster in clusters {
                    if let Some(cluster_object) = cluster.as_object() {
                        for (key, value) in cluster_object {
                            if key.starts_with("id") && value.as_str() == Some(&id) {
                                if let Some(uuid) =
                                    cluster_object.get("uuid").and_then(|uuid| uuid.as_str())
                                {
                                    return uuid.to_string();
                                }
                            }
                        }
                    }
                }
            }
        }
    }
    Uuid::new_v4().to_string()
}

#[cfg(test)]
mod tests {
    use super::*;
    use std::fs;
    use tempfile::TempDir;

    #[test]
    fn test_cluster_id() {
        let temp_dir = TempDir::new().unwrap();
        let file_path = temp_dir.path().join("clusters_test.json");

        let test_json = r#"
      {
        "clusters": [
          {
            "id1": "123",
            "id2": "456",
            "uuid": "uuid-123-456"
          },
          {
            "id1": "789",
            "uuid": "uuid-789"
          }
        ]
      }"#;

        fs::write(&file_path, test_json).unwrap();
        unsafe {
            env::set_var("CLUSTER_JSON_PATH", file_path.to_str().unwrap());
        }

        assert_eq!(cluster_id("123".to_string()), "uuid-123-456".to_string());
        assert_eq!(cluster_id("789".to_string()), "uuid-789".to_string());
        assert_eq!(cluster_id("840".to_string()).len(), 36); 
    }
}
