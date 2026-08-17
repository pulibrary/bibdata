// use base64::{Engine as _, engine::general_purpose::STANDARD};
use flate2::{Compression, write::GzEncoder};
use marctk::Record;
use std::io::Write;

// pub fn marc21_binary_b64(record: &Record) -> Result<String, Box<dyn std::error::Error>> {
//     let bytes = record.to_binary()?; // raw MARC21 (ISO2709) bytes
//     Ok(STANDARD.encode(bytes)) // JSON-safe base64
// }

// pub fn marc21_binary_raw(record: &Record) -> Result<Vec<u8>, Box<dyn std::error::Error>> {
//     let bytes = record.to_binary()?; // raw MARC21 (ISO2709) bytes
//     Ok(bytes)
// }

pub fn marc21_binary_gz_raw_bytes(record: &Record) -> Result<Vec<u8>, Box<dyn std::error::Error>> {
    let bytes = record.to_binary()?; // raw MARC21 (ISO2709) bytes

    let mut encoder = GzEncoder::new(Vec::new(), Compression::default());
    encoder.write_all(&bytes)?; // gzip-compress the bytes
    let compressed = encoder.finish()?; // return compressed bytes

    Ok(compressed)
}
