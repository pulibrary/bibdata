/// This binary downloads the MARC Code List for Geographic Areas from the Library of
/// Congress and saves it as json: `standards/data/geographic_areas.json`.
/// It intentionally includes discontinued codes.
/// To generate the json file run:
/// cargo run -p standards --bin update_geographic_areas
use std::{collections::BTreeMap, fmt::Display, fs::File};

use reqwest::blocking::Client;
use scraper::{Html, Selector};

const GEOGRAPHIC_AREAS_URL: &str = "https://www.loc.gov/marc/geoareas/gacs_code.html";

#[derive(Debug)]
pub enum UpdateGeographicAreasError {
    Downloading(reqwest::Error),
    Disk,
    Serialization(serde_json::Error),
}

impl Display for UpdateGeographicAreasError {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        match self {
            UpdateGeographicAreasError::Downloading(err) => {
                write!(f, "could not download the geographic area code list: {err}")
            }
            UpdateGeographicAreasError::Disk => write!(f, "could not write to disk"),
            UpdateGeographicAreasError::Serialization(err) => {
                write!(
                    f,
                    "could not serialize the geographic area code list: {err}"
                )
            }
        }
    }
}

impl std::error::Error for UpdateGeographicAreasError {
    fn source(&self) -> Option<&(dyn std::error::Error + 'static)> {
        match self {
            UpdateGeographicAreasError::Downloading(err) => Some(err),
            UpdateGeographicAreasError::Disk => None,
            UpdateGeographicAreasError::Serialization(err) => Some(err),
        }
    }
}

fn download_areas() -> Result<String, UpdateGeographicAreasError> {
    let client = Client::builder()
        .user_agent("Update-Geographic-Areas")
        .build()
        .unwrap();
    client
        .get(GEOGRAPHIC_AREAS_URL)
        .send()
        .and_then(|response| response.text())
        .map_err(UpdateGeographicAreasError::Downloading)
}

fn parse_areas(html: &str) -> BTreeMap<String, String> {
    let document = Html::parse_document(html);
    let table_selector = Selector::parse("table").unwrap();
    let table = document.select(&table_selector).next().unwrap();
    let row_selector = Selector::parse("tr").unwrap();
    let cell_selector = Selector::parse("td").unwrap();
    let mut areas = BTreeMap::new();
    for row in table.select(&row_selector) {
        let cells: Vec<_> = row.select(&cell_selector).collect();
        if cells.len() != 2 {
            continue;
        }
        let code: String = cells[0].text().collect();
        let name: String = cells[1].text().collect();
        let code = code.trim();
        let name = name.trim();
        if !code.is_empty() && !name.is_empty() {
            areas.insert(code.to_string(), name.to_string());
        }
    }
    areas
}

fn write_serialized(areas: BTreeMap<String, String>) -> Result<(), UpdateGeographicAreasError> {
    let path = std::path::Path::new(env!("CARGO_MANIFEST_DIR"))
        .join("data")
        .join("geographic_areas.json");
    let file = File::create(&path).map_err(|_| UpdateGeographicAreasError::Disk)?;
    serde_json::to_writer_pretty(file, &areas)
        .map_err(UpdateGeographicAreasError::Serialization)?;
    Ok(())
}

fn main() -> Result<(), Box<dyn std::error::Error>> {
    let html = download_areas()?;
    let areas = parse_areas(&html);
    write_serialized(areas)?;
    Ok(())
}

#[cfg(test)]
mod tests {
    use super::parse_areas;

    const HTML: &str = r#"
    <table>
      <tr><th>code</th><th>geographic area</th></tr>
      <tr><td class="code"><a id="a" name="a">a</a></td><td>Asia</td></tr>
      <tr><td class="code">a-cc</td><td>China</td></tr>
      <tr><td class="code">-a-ok</td><td>Okinawa</td></tr>
      <tr><td class="code">c-st</td><td>São Tomé and Príncipe</td></tr>
      <tr><td class="code">e-arg</td><td>Argentina (South America)</td></tr>
    </table>
    <table>
      <tr valign="bottom"><td>footer-a</td><td>footer-b</td><td>footer-c</td></tr>
    </table>
    "#;

    #[test]
    fn unwraps_anchor_wrapped_code() {
        let areas = parse_areas(HTML);
        // The code cell `<a id="a" name="a">a</a>` resolves to just "a".
        assert_eq!(areas.get("a"), Some(&"Asia".to_string()));
        assert!(!areas.contains_key("<a id=\"a\" name=\"a\">a</a>"));
    }

    #[test]
    fn is_sorted_by_code() {
        let areas = parse_areas(HTML);
        let keys: Vec<&String> = areas.keys().collect();
        let mut sorted = keys.clone();
        sorted.sort();
        assert_eq!(keys, sorted);
    }
}
