use crate::marc::{
    extract_values::ExtractValues,
    string_normalize::maybe_not_empty,
    title::UNIFORM_TITLE_240_SUBLFIELDS,
    trim_punctuation,
    variable_length_field::{
        ScriptsToIndex, SubfieldIterator, combine_consecutive_whitespace, field_tag_matches,
        join_subfields_by_code, latin_or_non_latin_tag, latin_or_non_latin_tag_included_in,
    },
};
use itertools::Itertools;
use marctk::{Field, Record};

pub fn name_title_browse_s(record: &Record) -> impl Iterator<Item = String> {
    let entries = [
        analytical_entries(record),
        linked_titles(record),
        related_works(record),
        contains_entries(record),
        author_and_title(record),
    ];
    entries.into_iter().flatten().unique()
}

/// A single name/title heading, split at its first `$t`.
#[derive(Debug, PartialEq)]
struct NameTitle {
    name: String,
    title_levels: Vec<String>,
}

impl NameTitle {
    fn from_field(field: &Field) -> Option<NameTitle> {
        field.first_subfield("a")?;

        let allowed = entry_subfields(latin_or_non_latin_tag(field))?;
        let subfields: Vec<_> = field.subfields().iter().filter_by_code(allowed).collect();

        // Require both a title (`$t`) and a name (`$a`); otherwise there is no
        // name/title heading to build.
        let at_title = subfields
            .iter()
            .position(|subfield| subfield.code() == "t")?;

        let name = subfields[..at_title]
            .iter()
            .map(|subfield| subfield.content())
            .join(" ");
        let title_levels = subfields[at_title..]
            .iter()
            .map(|subfield| subfield.content().to_owned())
            .collect();
        Some(NameTitle { name, title_levels })
    }

    fn headings(&self, include_name: bool) -> Vec<String> {
        let mut joined = self.name.clone();
        let mut headings = if include_name {
            vec![normalized(&joined)]
        } else {
            vec![]
        };
        for level in &self.title_levels {
            joined.push(' ');
            joined.push_str(level);
            headings.push(normalized(&joined));
        }
        headings
    }
}

fn normalized(heading: &str) -> String {
    trim_punctuation(&combine_consecutive_whitespace(heading))
}

fn entry_subfields(tag: &str) -> Option<&'static [&'static str]> {
    match tag {
        "700" | "800" => Some(&[
            "a", "b", "c", "d", "f", "g", "h", "k", "l", "m", "n", "o", "p", "q", "r", "s", "t",
            "x",
        ]),
        "710" | "810" => Some(&[
            "a", "b", "c", "d", "f", "g", "h", "k", "l", "n", "o", "p", "r", "s", "t", "x",
        ]),
        "711" | "811" => Some(&[
            "a", "b", "c", "d", "e", "f", "g", "k", "l", "n", "p", "q", "t",
        ]),
        _ => None,
    }
}

/// 7xx/8xx name+title entries for the given tags
fn added_entries(
    record: &Record,
    tags: &[&str],
    second_indicator: Option<&str>,
    include_name: bool,
) -> Vec<String> {
    record
        .fields()
        .iter()
        .filter(|field| latin_or_non_latin_tag_included_in(tags)(field))
        .filter(|field| second_indicator_matches(field, second_indicator))
        .filter_map(|field| NameTitle::from_field(field).map(|entry| entry.headings(include_name)))
        .flatten()
        .collect()
}

/// 8xx analytical entries: the entire name/title hierarchy, including the name.
fn analytical_entries(record: &Record) -> Vec<String> {
    added_entries(record, &["800", "810", "811"], None, true)
}

/// 7xx related works
fn related_works(record: &Record) -> Vec<String> {
    // A blank 2nd indicator is read back from MARC as a single space.
    added_entries(record, RELATED_TAGS, Some(" "), false)
}

/// 7xx "contains" entries
fn contains_entries(record: &Record) -> Vec<String> {
    added_entries(record, RELATED_TAGS, Some("2"), false)
}

const RELATED_TAGS: &[&str] = &["700", "710", "711"];

fn second_indicator_matches(field: &Field, desired: Option<&str>) -> bool {
    match desired {
        None => true,
        Some(indicator) => field.ind2() == indicator,
    }
}

/// 76x/77x/78x linkage entries: a single joined "$a $t", indexed only when the
/// field carries both a name and a title.
fn linked_titles(record: &Record) -> Vec<String> {
    record
        .fields()
        .iter()
        .filter(|field| LINKED_TITLE_TAGS.contains(&latin_or_non_latin_tag(field)))
        .filter_map(linked_title)
        .collect()
}

const LINKED_TITLE_TAGS: &[&str] = &[
    "760", "762", "765", "767", "770", "772", "773", "774", "775", "776", "777", "780", "785",
    "786", "787",
];

fn linked_title(field: &Field) -> Option<String> {
    if !field.has_subfield("a") || !field.has_subfield("t") {
        return None;
    }
    let joined = field
        .subfields()
        .iter()
        .filter_by_code(&["a", "t"])
        .join(" ");
    maybe_not_empty(normalized(&joined))
}

/// The main entry (100/110/111) joined with a 240 uniform title, or the 245$a
/// title.
fn author_and_title(record: &Record) -> Vec<String> {
    [ScriptsToIndex::LatinOnly, ScriptsToIndex::NonLatinOnly]
        .into_iter()
        .flat_map(|scripts| author_and_title_for(record, scripts))
        .collect()
}

fn author_and_title_for(record: &Record, scripts: ScriptsToIndex) -> Vec<String> {
    let Some(author) = first_author(record, scripts) else {
        return vec![];
    };
    let author = format!("{author}."); // e.g. "Author, Name."

    // A 240 uniform title wins over a 245$a title.
    let uniform_title = first_uniform_240(record, scripts);
    if !uniform_title.is_empty() {
        return NameTitle {
            name: author,
            title_levels: uniform_title,
        }
        .headings(false);
    }
    if let Some(title) = main_title(record, scripts) {
        return vec![format!("{author} {title}")];
    }
    vec![]
}

const MAIN_ENTRY_TAGS: &[&str] = &["100", "110", "111"];

/// The first non-empty main-entry name, trimmed of trailing punctuation.
fn first_author(record: &Record, scripts: ScriptsToIndex) -> Option<String> {
    record
        .first_matching_field_value(
            |field| field_tag_matches(field, scripts, MAIN_ENTRY_TAGS),
            main_entry_value,
        )
        .and_then(|joined| maybe_not_empty(trim_punctuation(&joined)))
}

fn main_entry_value(field: &Field) -> Option<String> {
    let subfields = main_entry_subfields(latin_or_non_latin_tag(field))?;
    maybe_not_empty(join_subfields_by_code(field, subfields))
}

fn main_entry_subfields(tag: &str) -> Option<&'static [&'static str]> {
    match tag {
        "100" => Some(&["a", "q", "b", "c", "d", "k"]),
        "110" => Some(&["a", "b", "c", "d", "f", "g", "k", "l", "n"]),
        "111" => Some(&["a", "b", "c", "d", "f", "g", "k", "l", "n", "p", "q"]),
        _ => None,
    }
}

/// The subfields of the first 240 uniform title field, in field order.  Empty
/// when there is no uniform title, or when it carries no relevant subfields.
fn first_uniform_240(record: &Record, scripts: ScriptsToIndex) -> Vec<String> {
    record
        .fields()
        .iter()
        .find(|field| field_tag_matches(field, scripts, &["240"]))
        .into_iter()
        .flat_map(|field| {
            field
                .subfields()
                .iter()
                .filter_by_code(UNIFORM_TITLE_240_SUBLFIELDS)
                .map(|subfield| subfield.content().to_owned())
        })
        .collect()
}

fn main_title(record: &Record, scripts: ScriptsToIndex) -> Option<String> {
    record
        .fields()
        .iter()
        .find(|field| field_tag_matches(field, scripts, &["245"]))
        .and_then(|field| field.first_subfield("a"))
        .and_then(|subfield| maybe_not_empty(trim_punctuation(subfield.content())))
}

#[cfg(test)]
mod tests {
    use marctk::Record;

    use super::*;

    #[test]
    fn related_work_keeps_only_the_title_portion_of_the_hierarchy() {
        let record = Record::from_breaker("=700 1 $aDoe, Jane $tWild in the streets").unwrap();
        assert_eq!(
            related_works(&record),
            vec!["Doe, Jane Wild in the streets"]
        );
        assert!(contains_entries(&record).is_empty());
    }

    #[test]
    fn corporate_and_meeting_related_works_are_both_indexed() {
        let record =
            Record::from_breaker("=710 2 $aCorp Name, $tA report\n=711 2 $aMeet Name, $tA session")
                .unwrap();
        assert_eq!(
            related_works(&record),
            vec!["Corp Name, A report", "Meet Name, A session"]
        );
    }

    #[test]
    fn a_2nd_indicator_of_2_marks_a_contains_entry() {
        let record = Record::from_breaker("=700 12$aSmith, John $tContains title").unwrap();
        assert_eq!(
            contains_entries(&record),
            vec!["Smith, John Contains title"]
        );
        assert!(related_works(&record).is_empty());
    }

    #[test]
    fn neither_an_ordinary_7xx_nor_a_700_subject_is_indexed() {
        // 2nd indicator 1 is neither a related work (blank) nor "contains" (2).
        let record = Record::from_breaker("=700 11$aFoo, Bar $tIgnored title").unwrap();
        assert!(name_title_browse_s(&record).collect::<Vec<_>>().is_empty());
    }

    #[test]
    fn a_name_without_a_title_is_dropped() {
        let record = Record::from_breaker("=700 1 $aDoe, Jane $d1900").unwrap();
        assert!(name_title_browse_s(&record).collect::<Vec<_>>().is_empty());
    }

    #[test]
    fn an_800_produces_the_full_hierarchy_including_the_name() {
        let record = Record::from_breaker("=800 1 $aPoe, Allan $bE. $tTales $n1").unwrap();
        assert_eq!(
            analytical_entries(&record),
            vec![
                "Poe, Allan E.",
                "Poe, Allan E. Tales",
                "Poe, Allan E. Tales 1"
            ]
        );
    }

    #[test]
    fn an_810_and_811_are_indexed() {
        let record =
            Record::from_breaker("=810 2 $aUniv. $bLib. $tReports\n=811 2 $aCongress $tPapers")
                .unwrap();
        assert_eq!(
            analytical_entries(&record),
            vec![
                "Univ. Lib",
                "Univ. Lib. Reports",
                "Congress",
                "Congress Papers"
            ]
        );
    }

    #[test]
    fn duplicate_analytical_entries_are_de_duplicated() {
        let record = Record::from_breaker(
            "=800 1 $aDup, Author, $tSame title\n=800 1 $aDup, Author, $tSame title",
        )
        .unwrap();
        assert_eq!(
            name_title_browse_s(&record).collect::<Vec<_>>(),
            vec!["Dup, Author", "Dup, Author, Same title"]
        );
    }

    #[test]
    fn a_linkage_heading_indexes_only_when_both_a_and_t_are_present() {
        let record = Record::from_breaker(
            "=765 \\ $aBoth $tname and title\n=770 \\ $tOnlyTitle\n=780 \\ $aOnlyName",
        )
        .unwrap();
        assert_eq!(linked_titles(&record), vec!["Both name and title"]);
        assert!(contains_entries(&record).is_empty());
    }

    #[test]
    fn author_is_joined_with_a_240_uniform_title() {
        let record =
            Record::from_breaker("=100 1 $aAuthor, Name,\n=240 10 $aUniform Title, $p5").unwrap();
        assert_eq!(
            author_and_title(&record),
            vec![
                "Author, Name. Uniform Title",
                "Author, Name. Uniform Title, 5"
            ]
        );
    }

    #[test]
    fn a_240_uniform_title_wins_over_a_245_title() {
        let record = Record::from_breaker(
            "=100 1 $aAuthor, X,\n=240 10 $aUniform,\n=245 10 $aShould be ignored",
        )
        .unwrap();
        assert_eq!(author_and_title(&record), vec!["Author, X. Uniform"]);
    }

    #[test]
    fn author_is_joined_with_the_245_title_when_there_is_no_uniform_title() {
        let record =
            Record::from_breaker("=110 2 $aUnited States, $bDept.\n=245 10 $aReport title")
                .unwrap();
        assert_eq!(
            author_and_title(&record),
            vec!["United States, Dept. Report title"]
        );
    }

    #[test]
    fn only_the_first_author_is_combined() {
        let record = Record::from_breaker(
            "=110 2 $aCorp,\n=111 2 $aMeeting,\n=100 1 $aMain, Author,\n=245 10 $aSome Title",
        )
        .unwrap();
        assert_eq!(author_and_title(&record), vec!["Corp. Some Title"]);
    }

    #[test]
    fn an_880_alternate_script_author_is_indexed_with_a_240() {
        let record = Record::from_breaker(
             "=100 \\ $6880-01 $aأحمد, الطاهري\n=880 \\ $6100-01 $aAhmad, Al-Tahri\n=240 \\ $6880-02 $aالوصفة $p1\n=880 \\ $6240-02 $aRecipe $p1",
         )
         .unwrap();
        assert_eq!(
            author_and_title(&record),
            vec![
                "أحمد, الطاهري. الوصفة",
                "أحمد, الطاهري. الوصفة 1",
                "Ahmad, Al-Tahri. Recipe",
                "Ahmad, Al-Tahri. Recipe 1",
            ]
        );
    }

    #[test]
    fn a_cyrillic_880_author_uses_the_880_245_title() {
        let record = Record::from_breaker(
             "=100 \\ $6880-01 $aНиколай, Чибисов\n=880 \\ $6100-01 $aNikolai, Chibisov\n=245 \\ $6880-02 $aДневник\n=880 \\ $6245-02 $aDiary, Vol. 5",
         )
         .unwrap();
        assert_eq!(
            author_and_title(&record),
            vec![
                "Николай, Чибисов. Дневник",
                "Nikolai, Chibisov. Diary, Vol. 5"
            ]
        );
    }

    #[test]
    fn it_combines_every_component() {
        let record = Record::from_breaker(
             "=700 1 $aRel, Name, $tRel title\n=710 22$aCont, Corp, $tCont title\n=765 \\ $aLink $tlinked title\n=800 1 $aAE, Author, $tAE title\n=100 \\ $6880-01 $aMaría, Chef\n=880 \\ $6100-01 $aأحمد الطاهري\n=240 \\0 $6880-02 $aUniform, Latin\n=880 \\ $6240-02 $aالمثالي\n=245 10 $aRecipe for Tacos",
         )
         .unwrap();
        assert_eq!(
            name_title_browse_s(&record).collect::<Vec<_>>(),
            vec![
                "AE, Author",
                "AE, Author, AE title",
                "Link linked title",
                "Rel, Name, Rel title",
                "Cont, Corp, Cont title",
                "María, Chef. Uniform, Latin",
                "أحمد الطاهري. المثالي",
            ]
        );
    }

    #[test]
    fn a_title_only_record_with_no_added_entries_contributes_nothing() {
        let record = Record::from_breaker("=245 10 $aJust a title").unwrap();
        assert!(name_title_browse_s(&record).collect::<Vec<_>>().is_empty());
    }

    #[test]
    fn a_lone_author_with_no_title_contributes_nothing() {
        let record = Record::from_breaker("=700 1 $aLone, Author, $d1900").unwrap();
        assert!(name_title_browse_s(&record).collect::<Vec<_>>().is_empty());
    }
}
