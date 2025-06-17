use marctk::Record;

pub fn no_longer_published(record: Record) -> bool {
    true
}

#[cfg(test)]
mod tests {
    use marctk::Record;

    use crate::marc::date::no_longer_published;

    #[test]
    fn it_can_tell_if_it_is_no_longer_published() {
        let record = Record::from_breaker(
            r#"=600 \\$aExclude$vJohn$xJoin
=630 \0$xFiction.
=655 \\$aCulture.$xDramatic rendition$vAwesome
=655 \\$aPoetry$xTranslations into French$vMaps
=655 \\$aManuscript$xTranslations into French$vGenre$2rbgenr"#,
        )
        .unwrap();
    assert!(!no_longer_published(record));
    }
}