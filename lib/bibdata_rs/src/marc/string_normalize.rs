use std::sync::LazyLock;

use regex::Regex;

/// A re-implementation of traject's trim_punctuation macro.
/// Unlike the original, it does not mutate the provided string,
/// but rather allocates a new string
/// See https://github.com/traject/traject/blob/8957f842d1e0461f2b38ac85e7f9876d3ec757a0/lib/traject/macros/marc21.rb#L241-L271
/// for the original implementation
pub fn trim_punctuation(string: &str) -> String {
    // comma, slash, semicolon, colon (possibly preceded and followed by whitespace)
    static TRAILING: LazyLock<Regex> = LazyLock::new(|| Regex::new(r" *[ ,\/;:] *\z").unwrap());

    // trailing period if it is preceded by at least three letters (possibly preceded and followed by whitespace)
    static TRAILING_PERIOD: LazyLock<Regex> =
        LazyLock::new(|| Regex::new(r"( *\w{3,}) *\.*\z").unwrap());

    // single square bracket characters if they are the start and/or end
    //   chars and there are no internal square brackets.
    static SINGLE_SQUARE_BRACKET: LazyLock<Regex> =
        LazyLock::new(|| Regex::new(r"\A\[?([^\[\]]+)\]?\z").unwrap());

    let no_trailing = TRAILING.replace(string, "");
    let no_trailing_period = TRAILING_PERIOD.replace(&no_trailing, "$1");
    SINGLE_SQUARE_BRACKET
        .replace(&no_trailing_period, "$1")
        .trim()
        .to_owned()
}

pub fn strip_non_numeric(string: &str) -> String {
    string
        .chars()
        // remove preceding zeroes
        .skip_while(|c| !c.is_numeric() || c == &'0')
        .filter(|c| c.is_numeric())
        .collect()
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn it_trims_punctuation() {
        assert_eq!("one two three", trim_punctuation("one two three"));
        assert_eq!("one two three", trim_punctuation("one two three,"));
        assert_eq!("one two three", trim_punctuation("one two three/"));
        assert_eq!("one two three", trim_punctuation("one two three;"));
        assert_eq!("one two three", trim_punctuation("one two three:"));
        assert_eq!("one two three", trim_punctuation("one two three ."));
        assert_eq!("one two three", trim_punctuation("one two three."));
        assert_eq!("one two three", trim_punctuation("one two three..."));
        assert_eq!("one two three", trim_punctuation(" one two three."));

        assert_eq!("one two [three]", trim_punctuation("one two [three]"));
        assert_eq!("one two three", trim_punctuation("one two three]"));
        assert_eq!("one two three", trim_punctuation("[one two three"));
        assert_eq!("one two three", trim_punctuation("[one two three]"));

        assert_eq!("Feminism and art", trim_punctuation("Feminism and art."));
        assert_eq!("Le réve", trim_punctuation("Le réve."));
        assert_eq!("Bill Dueber, Jr.", trim_punctuation("Bill Dueber, Jr."));
    }
}
