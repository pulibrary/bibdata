use std::{borrow::Cow, sync::LazyLock};

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

    let no_trailing = TRAILING.replace(string, "");
    let no_trailing_period = TRAILING_PERIOD.replace(&no_trailing, "$1");
    trim_starting_and_ending_brackets(&no_trailing_period)
        .trim()
        .to_owned()
}

fn trim_starting_and_ending_brackets(original: &str) -> Cow<'_, str> {
    let trimmed = original
        .strip_prefix('[')
        .map(|start_trimmed| start_trimmed.strip_suffix(']').unwrap_or(start_trimmed))
        .or(original.strip_suffix(']'));
    match trimmed {
        // Make sure the string does not contain any remaining [], since they might have
        // been paired with the ones we just removed, in which case the trimmed string
        // won't make sense and we should return the original.
        Some(trimmed) if !trimmed.contains('[') && !trimmed.contains(']') => {
            Cow::Owned(trimmed.to_owned())
        }
        _ => Cow::Borrowed(original),
    }
}

pub fn strip_non_numeric(string: &str) -> String {
    string
        .chars()
        // remove preceding zeroes
        .skip_while(|c| !c.is_numeric() || c == &'0')
        .filter(|c| c.is_numeric())
        .collect()
}

pub fn upcase_first(string: &str) -> Cow<'_, str> {
    let mut chars = string.chars();
    match chars.next() {
        Some(first) if first.is_uppercase() => Cow::Borrowed(string),
        Some(first) => Cow::Owned(first.to_uppercase().collect::<String>() + chars.as_str()),
        None => Cow::Borrowed(Default::default()),
    }
}

pub fn maybe_not_empty<S>(s: S) -> Option<S>
where
    S: AsRef<str>,
{
    if s.as_ref().is_empty() { None } else { Some(s) }
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

    #[test]
    fn it_strips_non_numeric() {
        assert_eq!(strip_non_numeric("abc"), "");
        assert_eq!(strip_non_numeric("123"), "123");
        assert_eq!(strip_non_numeric("0123"), "123");
        assert_eq!(strip_non_numeric("abc0123"), "123");
        assert_eq!(strip_non_numeric("0abc123"), "123");
        assert_eq!(strip_non_numeric("000abc123"), "123");
        assert_eq!(strip_non_numeric("000abc0123"), "123");
        assert_eq!(strip_non_numeric("1024"), "1024");
        assert_eq!(strip_non_numeric("a1b0c2d4e"), "1024");
        assert_eq!(strip_non_numeric("300"), "300");
        assert_eq!(strip_non_numeric("3abcd00"), "300");
    }

    #[test]
    fn it_can_upcase_first() {
        assert_eq!(upcase_first("dog"), "Dog");
        assert_eq!(upcase_first("Dog"), "Dog");
        assert_eq!(upcase_first(""), "");
    }
}
