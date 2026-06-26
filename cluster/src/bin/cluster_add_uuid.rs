use serde_json::{Value, json};
use std::fs;
use uuid::Uuid;
fn main() {
    let file_path = "cluster/data/b2011.json";
    let file_content = fs::read_to_string(file_path).expect("Failed to read the file");
    let mut json_data: Value = serde_json::from_str(&file_content).expect("Failed to parse JSON");

    let mut updated_data = json!({"clusters": []});
    if let Some(clusters) = json_data["clusters"].as_array_mut() {
        for cluster in clusters {
            if let Some(cluster_array) = cluster.as_array_mut() {
                if !cluster_array.is_empty() {
                    let uuid = Uuid::new_v4();
                    let mut cluster_object = json!({});

                    for (index, id_value) in cluster_array.iter().enumerate() {
                        let id_key = format!("id{}", index + 1);
                        cluster_object[id_key] = json!(id_value.as_str().unwrap_or(""));
                    }
                    cluster_object["uuid"] = json!(uuid.to_string());
                    updated_data["clusters"]
                        .as_array_mut()
                        .unwrap()
                        .push(cluster_object);
                }
            }
        }
    }
    let output_path = "cluster/data/clusters_with_uuid.json";
    fs::write(
        output_path,
        serde_json::to_string_pretty(&updated_data).expect("Failed to serialize JSON"),
    )
    .expect("Failed to write JSON file");
}
