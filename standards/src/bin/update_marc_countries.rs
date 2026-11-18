//! Regenerate the `marc_countries.json` and `marc_countries_hierarchical_pipe.json`
//! data files from the YAML translation maps in `marc_to_solr/translation_maps/`.
//!
//! Run with: `cargo run -p standards --bin update_marc_countries`
//!
//! The YAML files are the source of truth. This binary converts them to JSON
//! for faster Rust deserialization via `include_str!`.

use std::fs;
use std::path::Path;

use serde_yaml::Value;

/// Convert a YAML translation map to a JSON file.
///
/// The YAML map may contain:
/// - Scalar values (e.g. `'miu': 'Michigan'`)
/// - List values (e.g. `'miu': ['United States', 'United States|||Michigan']`)
///
/// Both are serialized as JSON with the same structure.
fn convert_yaml_to_json(yaml_path: &str, output_path: &str) {
    let yaml_data =
        fs::read_to_string(yaml_path).unwrap_or_else(|e| panic!("Failed to read {yaml_path}: {e}"));

    let yaml_map: Value = serde_yaml::from_str(&yaml_data)
        .unwrap_or_else(|e| panic!("Failed to parse YAML from {yaml_path}: {e}"));

    let json = serde_json::to_string_pretty(&yaml_map)
        .unwrap_or_else(|e| panic!("Failed to serialize to JSON: {e}"));

    if let Some(parent) = Path::new(output_path).parent() {
        fs::create_dir_all(parent)
            .unwrap_or_else(|e| panic!("Failed to create directory {parent:?}: {e}"));
    }

    fs::write(output_path, format!("{json}\n"))
        .unwrap_or_else(|e| panic!("Failed to write {output_path}: {e}"));

    println!("Wrote {output_path}");
}

fn main() {
    let yaml_dir = "marc_to_solr/translation_maps";
    let output_dir = "standards/data";

    convert_yaml_to_json(
        &format!("{yaml_dir}/marc_countries.yaml"),
        &format!("{output_dir}/marc_countries.json"),
    );

    convert_yaml_to_json(
        &format!("{yaml_dir}/marc_countries_hierarchical_pipe.yaml"),
        &format!("{output_dir}/marc_countries_hierarchical_pipe.json"),
    );

    println!("Done. Updated MARC country translation maps.");
}
