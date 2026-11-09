pub mod holding_location;
pub mod library;
pub mod partner;
use crate::marc::string_normalize::maybe_not_empty;
use itertools::Itertools;
use marctk::Field;
use std::ops::Deref;

pub struct Field852<'a>(&'a Field);

impl<'a> Field852<'a> {
    fn get(&self, subfield_code: &str) -> Option<&'a str> {
        self.0
            .first_subfield(subfield_code)
            .map(|subfield| subfield.content())
    }

    pub fn sublocation(&self) -> Option<&'a str> {
        self.get("b")
    }

    pub fn call_number_prefix(&self) -> Option<&'a str> {
        self.get("k")
    }

    pub fn shelving_form_of_title(&self) -> Option<&'a str> {
        self.get("l")
    }

    pub fn public_note(&self) -> Option<&'a str> {
        self.get("z")
    }

    pub fn call_number(&self) -> Option<String> {
        let call_number = self
            .0
            .subfields()
            .iter()
            .filter(|subfield| ["h", "i", "k", "j"].contains(&subfield.code()))
            .map(|subfield| subfield.content().to_string())
            .filter(|s| !s.is_empty())
            .join(" ");
        maybe_not_empty(call_number)
    }
}

impl Deref for Field852<'_> {
    type Target = Field;

    fn deref(&self) -> &Self::Target {
        self.0
    }
}

pub struct Field876<'a>(&'a Field);

impl<'a> Field876<'a> {
    fn get(&self, subfield_code: &str) -> Option<&'a str> {
        self.0
            .first_subfield(subfield_code)
            .map(|subfield| subfield.content())
    }

    pub fn materials_specified(&self) -> Option<&'a str> {
        self.get("3")
    }

    pub fn internal_item_number(&self) -> Option<&'a str> {
        self.get("a")
    }

    pub fn item_status(&self) -> Option<&'a str> {
        self.get("j")
    }

    /// barcode
    pub fn piece_designation(&self) -> Option<&'a str> {
        self.get("p")
    }

    pub fn copy_number(&self) -> Option<&'a str> {
        self.get("t")
    }

    pub fn use_restrictions(&self) -> Option<&'a str> {
        self.get("h")
    }

    pub fn temporary_location(&self) -> Option<&'a str> {
        self.get("l")
    }

    /// Recap records use this for the Collection Group Designation (CGD)
    pub fn nonpublic_note(&self) -> Option<&'a str> {
        self.get("x")
    }

    pub fn public_note(&self) -> Option<&'a str> {
        self.get("z")
    }
}

impl Deref for Field876<'_> {
    type Target = Field;

    fn deref(&self) -> &Self::Target {
        self.0
    }
}

pub trait Holding {}
pub trait Item {}

// Get the $a and $z from an 866, 867, or 868 field
fn textual_holdings(field: &Field) -> Option<String> {
    let mut text = field
        .first_subfield("a")
        .into_iter()
        .map(|sf| sf.content())
        .chain(field.first_subfield("z").into_iter().map(|sf| sf.content()));
    maybe_not_empty(text.join(" "))
}

#[cfg(test)]
mod tests {
    use marctk::Record;

    use super::*;

    #[test]
    fn field852_reads_named_subfields() {
        let record =
            Record::from_breaker(r#"=852 8\ $06769856$bscsbnypl$kSFX$l日本語資料$z公開メモ"#)
                .unwrap();
        let field = Field852(record.get_fields("852")[0]);
        assert_eq!(field.sublocation(), Some("scsbnypl"));
        assert_eq!(field.call_number_prefix(), Some("SFX"));
        assert_eq!(field.shelving_form_of_title(), Some("日本語資料"));
        assert_eq!(field.public_note(), Some("公開メモ"));
    }

    #[test]
    fn field852_holding_id_and_call_number() {
        let record = Record::from_breaker(r#"=852 8\ $hND1053.4$i.K5 1934$j905$06769856"#).unwrap();
        let field = Field852(record.get_fields("852")[0]);
        assert_eq!(field.get("0"), Some("6769856"));
        assert_eq!(
            field.call_number(),
            Some("ND1053.4 .K5 1934 905".to_string())
        );
    }

    #[test]
    fn field852_missing_subfields_are_none() {
        let record = Record::from_breaker(r#"=852 0\ $bfirestone"#).unwrap();
        let field = Field852(record.get_fields("852")[0]);
        assert_eq!(field.get("0"), None);
        assert_eq!(field.call_number_prefix(), None);
        assert_eq!(field.shelving_form_of_title(), None);
        assert_eq!(field.public_note(), None);
    }

    #[test]
    fn field876_reads_named_subfields() {
        let record = Record::from_breaker(
            r#"=876 \\ $06769856$33rd copy$a10924375$jAvailable$p33333081091841$t1$h借出可$lRECAP$xShared$zNH"#,
        )
        .unwrap();
        let field = Field876(record.get_fields("876")[0]);
        assert_eq!(field.get("0"), Some("6769856"));
        assert_eq!(field.materials_specified(), Some("3rd copy"));
        assert_eq!(field.internal_item_number(), Some("10924375"));
        assert_eq!(field.item_status(), Some("Available"));
        assert_eq!(field.piece_designation(), Some("33333081091841"));
        assert_eq!(field.copy_number(), Some("1"));
        assert_eq!(field.use_restrictions(), Some("借出可"));
        assert_eq!(field.temporary_location(), Some("RECAP"));
        assert_eq!(field.nonpublic_note(), Some("Shared"));
        assert_eq!(field.public_note(), Some("NH"));
    }

    #[test]
    fn field876_missing_subfields_are_none() {
        let record = Record::from_breaker(r#"=876 \\ $06769856"#).unwrap();
        let field = Field876(record.get_fields("876")[0]);
        assert_eq!(field.internal_item_number(), None);
        assert_eq!(field.piece_designation(), None);
        assert_eq!(field.nonpublic_note(), None);
        assert_eq!(field.public_note(), None);
    }
}
