use serde::Deserialize;
use serde_xml_rs::from_str;

#[derive(Debug, Deserialize)]
struct Metadata {
    #[serde(rename = "key")]
    key: String,
    #[serde(rename = "value")]
    value: String,
}

#[derive(Debug, Deserialize)]
struct Item {
    #[serde(rename = "metadata")]
    metadata: Vec<Metadata>,
}

#[derive(Debug, Deserialize)]
struct Items {
    #[serde(rename = "item")]
    items: Vec<Item>,
}

#[derive(Debug)]
struct ParsedData {
    authors: Vec<String>,
}

fn parse_xml(xml: &str) -> ParsedData {
    let items: Items = from_str(xml).expect("Failed to parse XML");

    let authors: Vec<String> = items
        .items
        .iter()
        .flat_map(|item| {
            item.metadata
                .iter()
                .filter(|m| m.key == "dc.contributor.author")
                .map(|m| m.value.clone())
        })
        .collect();

    ParsedData { authors }
}

#[cfg(test)]
mod tests {
    use super::*;
    #[test]
    fn does_it_work() {
        let xml_data = r#"<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
                <items>
                    <item>
                        <metadata>
                            <key>dc.contributor.author</key>
                            <value>Gaubatz, Piper Rae</value>
                        </metadata>
                        <metadata>
                            <key>dc.title</key>
                            <value>Example Title</value>
                        </metadata>
                    </item>
                    <item>
                        <metadata>
                            <key>dc.contributor.author</key>
                            <value>Clark, Erica L.</value>
                        </metadata>
                        <metadata>
                            <key>dc.title</key>
                            <value>Another Title</value>
                        </metadata>
                    </item>
                </items>
            "#;

        let parsed_data = parse_xml(xml_data);
        for author in parsed_data.authors {
            println!("Author: {}", author);
        }
    }
}
