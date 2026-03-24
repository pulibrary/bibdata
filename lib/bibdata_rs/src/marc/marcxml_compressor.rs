use base64::prelude::*;
use flate2::{Compression, write::GzEncoder};
use marctk::Record;
use std::io::Write;

pub fn marcxml_compressed(record: &Record) -> String {
    let marcxml_string = record.to_xml_string();
    let mut encoder = GzEncoder::new(Vec::new(), Compression::default());
    encoder.write_all(marcxml_string.as_bytes()).unwrap();
    let marcxml_compressed = encoder.finish().unwrap();
    BASE64_STANDARD.encode(marcxml_compressed)
}
