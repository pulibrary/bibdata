use marctk::Record;

// We use this SCSB check for multiple workflows
pub fn is_scsb(record: &Record) -> bool {
    record
        .get_control_fields("001")
        .iter()
        .any(|field| field.content().starts_with("SCSB-"))
}
