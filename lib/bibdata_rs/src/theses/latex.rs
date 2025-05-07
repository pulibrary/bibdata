use regex::{Captures, Regex};

pub fn normalize_latex(original: String) -> String {
    Regex::new(r"\\\(.*?\\\)")
        .unwrap()
        .replace_all(&original, |captures: &Captures| {
            captures[0]
                .chars()
                .filter(|c| c.is_alphanumeric())
                .collect::<String>()
        })
        .to_string()
}

#[cfg(test)]
mod tests {
    use super::*;
    #[test]
    fn it_normalizes_latex() {
        assert_eq!(
            normalize_latex(
                "2D \\(^{1}\\)H-\\(^{14}\\)N HSQC inverse-detection experiments".to_owned()
            ),
            "2D 1H-14N HSQC inverse-detection experiments"
        );
    }
}
