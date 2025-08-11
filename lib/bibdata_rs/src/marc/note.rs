use marctk::Record;

pub fn access_notes(record: &Record) -> Option<Vec<String>> {
    let notes: Vec<String> = record
        .extract_values("506(1*)a")
        .iter()
        .map(|note| note.trim().to_owned())
        .collect();
    if notes.is_empty() {
        None
    } else {
        Some(notes)
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn it_finds_access_notes_when_restrictions_apply() {
        let record = Record::from_breaker(
            r"=506 1\ $3 Princeton copy 1 $a For conservation reasons, access is granted for compelling reasons only: please consult the curator of the Cotsen Children's Library. $5 NjP"
        ).unwrap();

        let access_notes = access_notes(&record);
        assert_eq!(
            access_notes.unwrap(),
            vec!["For conservation reasons, access is granted for compelling reasons only: please consult the curator of the Cotsen Children's Library.".to_owned()]
        );
    }

    #[test]
    fn it_does_not_include_access_notes_when_unrestricted() {
        let record = Record::from_breaker(
            r"=506 0\ $aAccess copy available to the general public.$fUnrestricted$2star$5MH",
        )
        .unwrap();

        assert!(access_notes(&record).is_none());
    }
}
