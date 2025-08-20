use super::string_normalize::strip_non_numeric;

pub fn normalize_oclc_number(original: &str) -> String {
    let cleaned = strip_non_numeric(original);
    match cleaned.len() {
        1..=8 => format!("ocm{:0>8}", cleaned),
        9 => format!("ocn{cleaned}"),
        _ => format!("on{cleaned}"),
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn it_can_normalize_oclc_number() {
        assert_eq!(normalize_oclc_number("9913506421"), "on9913506421");
        assert_eq!(normalize_oclc_number("9913504"), "ocm09913504");
        assert_eq!(normalize_oclc_number("991350412"), "ocn991350412");
        assert_eq!(normalize_oclc_number("(OCoLC)882089266"), "ocn882089266");
        assert_eq!(normalize_oclc_number("(OCoLC)on9990014350"), "on9990014350");
        assert_eq!(normalize_oclc_number("(OCoLC)ocn899745778"), "ocn899745778");
        assert_eq!(normalize_oclc_number("(OCoLC)ocm00012345"), "ocm00012345");

        assert_eq!(
            normalize_oclc_number("(OCoLC)ocm00012345"),
            normalize_oclc_number("(OCoLC)12345")
        );
    }
}
