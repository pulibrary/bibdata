use crate::{
    data_pipeline::pipe,
    marc::{
        extract_values::ExtractValues,
        subject::{accumulate_hierarchical_heading, hierarchical_heading},
        utils::slice::contains_subslice,
        variable_length_field::{SubfieldIterator, latin_or_non_latin_tag_included_in},
    },
};

use super::{
    fixed_field::{BibliographicLevel, TypeOfRecord, literary_forms},
    trim_punctuation,
};
use itertools::Itertools;
use marctk::{Field, Record};
use std::sync::LazyLock;

mod biographical_content;

pub use biographical_content::BiographicalContent;

pub fn genres(record: &Record) -> Vec<String> {
    genres_from_subfield_v(record)
        .into_iter()
        .chain(genres_from_subfield_x(record))
        .chain(genres_from_subject_vocabularies(record))
        .chain(genres_from_primary_source_lcsh_mapping(record))
        .chain(genres_from_primary_source_lcgft_mapping(record))
        .chain(genres_from_biographical_content(record))
        .unique()
        .collect()
}

/// Get the genre terms from the record that use the specified vocabulary
fn genre_values(record: &Record, vocab: GenreVocabulary) -> impl Iterator<Item = String> {
    record.extract_field_values_by(
        move |field| {
            latin_or_non_latin_tag_included_in(&["655"])(field)
                && GenreVocabulary::from(field) == vocab
        },
        |field| Some(rare_books_genre_heading(field)),
    )
}

pub fn aat_s(record: &Record) -> impl Iterator<Item = String> {
    genre_values(record, GenreVocabulary::ArtArchitectureThesaurus)
}

pub fn homoit_genre_s(record: &Record) -> impl Iterator<Item = String> {
    genre_values(record, GenreVocabulary::Homosaurus)
}

pub fn lcgft_s(record: &Record) -> impl Iterator<Item = String> {
    genre_values(record, GenreVocabulary::LCGenreFormTerms)
}

pub fn rbgenr_s(record: &Record) -> impl Iterator<Item = String> {
    genre_values(
        record,
        GenreVocabulary::RareBooksManuscriptsGenreVocabularies,
    )
}

pub fn rbgenr_genre_facet(record: &Record) -> impl Iterator<Item = String> {
    record
        .extract_field_values_by(
            |field| {
                latin_or_non_latin_tag_included_in(&["655"])(field)
                    && matches!(
                        GenreVocabulary::from(field),
                        GenreVocabulary::RareBooksManuscriptsGenreVocabularies
                    )
            },
            pipe!(rare_books_genre_heading, accumulate_hierarchical_heading),
        )
        .flatten()
}

fn rare_books_genre_heading(field: &Field) -> String {
    hierarchical_heading(field, &["a", "v", "x", "y", "z"], |subfield| {
        ["v", "x", "y", "z"].contains(&subfield.code())
    })
}

const RARE_BOOKS_MANUSCRIPTS_GENRE_VOCABS: [&str; 8] = [
    "rbbin", "rbgenr", "rbmscv", "rbpap", "rbpri", "rbprov", "rbpub", "rbtyp",
];

#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum GenreVocabulary {
    ArtArchitectureThesaurus,
    Homosaurus,
    LCGenreFormTerms,
    RareBooksManuscriptsGenreVocabularies,
    UnknownVocabulary,
}

impl From<&Field> for GenreVocabulary {
    fn from(field: &Field) -> Self {
        match field.first_subfield("2") {
            Some(subfield) if subfield.content().trim() == "aat" => Self::ArtArchitectureThesaurus,
            Some(subfield) if subfield.content().trim() == "homoit" => Self::Homosaurus,
            Some(subfield) if subfield.content().trim() == "lcgft" => Self::LCGenreFormTerms,
            Some(subfield)
                if RARE_BOOKS_MANUSCRIPTS_GENRE_VOCABS.contains(&subfield.content().trim()) =>
            {
                Self::RareBooksManuscriptsGenreVocabularies
            }
            _ => Self::UnknownVocabulary,
        }
    }
}

fn genres_from_primary_source_lcsh_mapping(record: &Record) -> Vec<String> {
    if is_book(record) && is_literary_work(record) {
        return vec![];
    }
    if record
        .extract_values(
            "600(*0)vx:610(*0)vx:611(*0)vx:630(*0)vx:650(*0)vx:651(*0)vx:655(*0)a:655(*0)vx",
        )
        .iter()
        .any(|genre_term| does_lcsh_genre_term_indicate_primary_source(genre_term))
    {
        vec!["Primary sources".to_string()]
    } else {
        vec![]
    }
}

const GENRE_TERMS: &[&str] = &[
    "Bibliography",
    "Biography",
    "Catalogs",
    "Catalogues raisonnes",
    "Commentaries",
    "Congresses",
    "Diaries",
    "Dictionaries",
    "Drama",
    "Encyclopedias",
    "Exhibitions",
    "Fiction",
    "Guidebooks",
    "In art",
    "Indexes",
    "Librettos",
    "Manuscripts",
    "Newspapers",
    "Periodicals",
    "Pictorial works",
    "Poetry",
    "Portraits",
    "Scores",
    "Songs and music",
    "Sources",
    "Statistics",
    "Texts",
    "Translations",
];

const GENRE_STARTING_TERMS: &[&str] = &[
    "Census",
    "Maps",
    "Methods",
    "Parts",
    "Personal narratives",
    "Scores and parts",
    "Study and teaching",
    "Translations into ",
];

fn is_likely_genre_term(term: &str) -> bool {
    GENRE_TERMS.contains(&term)
        || GENRE_STARTING_TERMS
            .iter()
            .any(|starting_term| term.starts_with(starting_term))
}

// This struct is used to compare two terms and determine if one term
// contains another.  For example, the term "Fox art--Exhibitions" contains
// the term "Exhibitions"
struct ComparableTerm(Vec<String>);
impl ComparableTerm {
    pub fn contains(&self, part: &Self) -> bool {
        // Divide our term into windows of the same length as `part`.
        // For example, if `self`` is `ComparableTerm::from("Fox art Pictorial works")`
        // and `part` is ComparableTerm::from("Pictorial works"), windows will have
        // size 2 (the same as the number of words in "Pictorial works"), and the three
        // windows would be:
        //   * Fox art
        //   * art Pictorial
        //   * Pictorial works -- which is a match!!
        contains_subslice(&self.0, &part.0)
    }
}
impl From<&str> for ComparableTerm {
    // Normalize into a lower-case Vec<String> of words
    fn from(value: &str) -> Self {
        let non_word_character = |c: char| !c.is_alphanumeric();
        Self(
            value
                .split(non_word_character)
                .map(str::to_lowercase)
                .collect(),
        )
    }
}

type CombinedTerm = ComparableTerm;
type Subdivision = ComparableTerm;

static PRIMARY_SOURCE_GENRES: LazyLock<[Subdivision; 19]> = LazyLock::new(|| {
    [
        "atlases",
        "charters",
        "correspondence",
        "diaries",
        "documents",
        "interview",
        "interviews",
        "letters",
        "manuscripts",
        "maps",
        "notebooks, sketchbooks, etc",
        "oral history",
        "pamphlets",
        "personal narratives",
        "photographs",
        "pictorial works",
        "sources",
        "speeches",
        "statistics",
    ]
    .map(Subdivision::from)
});

fn does_lcsh_genre_term_indicate_primary_source(value: &str) -> bool {
    let term = CombinedTerm::from(value);
    PRIMARY_SOURCE_GENRES
        .iter()
        .any(|genre_subdivision| term.contains(genre_subdivision))
}

fn genres_from_biographical_content(record: &Record) -> Vec<String> {
    if matches!(
        BiographicalContent::from(record),
        BiographicalContent::Autobiography
    ) && !is_literary_book(record)
    {
        vec!["Primary sources".to_owned()]
    } else {
        vec![]
    }
}

fn genres_from_subfield_x(record: &Record) -> Vec<String> {
    record
        .extract_values("600(*0)x:610(*0)x:611(*0)x:630(*0)x:650(*0)x:651(*0)x:655(*0)x")
        .iter()
        .map(|genre| trim_punctuation(genre))
        .map(|genre| genre.trim().to_owned())
        .filter(|genre| !genre.is_empty())
        .filter(|genre| is_likely_genre_term(genre))
        .collect()
}

fn genres_from_subfield_v(record: &Record) -> Vec<String> {
    record
        .extract_values("600(*0)v:610(*0)v:611(*0)v:630(*0)v:650(*0)v:651(*0)v:655(*0)a:655(*0)v")
        .iter()
        .map(|genre| trim_punctuation(genre))
        .map(|genre| genre.trim().to_owned())
        .filter(|genre| !genre.is_empty())
        .collect()
}

const SUBJECT_GENRE_VOCABULARIES: &[&str] = &[
    "sk", "aat", "lcgft", "rbbin", "rbgenr", "rbmscv", "rbpap", "rbpri", "rbprov", "rbpub",
    "rbtyp", "homoit",
];

fn genres_from_subject_vocabularies(record: &Record) -> impl Iterator<Item = String> {
    record
        .extract_field_values_by(
            |field| {
                ["650", "655"].contains(&field.tag())
                    && field.ind2() == "7"
                    && any_vocabularies_match(field, SUBJECT_GENRE_VOCABULARIES)
            },
            |field| {
                Some(
                    field
                        .subfields()
                        .iter()
                        .filter_by_code(if field.tag() == "650" {
                            &["v"]
                        } else {
                            &["a", "v"]
                        })
                        .content()
                        .map(|genre| trim_punctuation(genre).to_string()),
                )
            },
        )
        .flatten()
}

fn any_vocabularies_match(field: &Field, vocabulary_codes: &[&str]) -> bool {
    field
        .first_subfield("2")
        .is_some_and(|subfield| vocabulary_codes.contains(&subfield.content().trim()))
}

static PRIMARY_SOURCE_LCGFT_GENRES: LazyLock<[Subdivision; 127]> = LazyLock::new(|| {
    [
        "Primary sources",
        "Call documents",
        "Charters and articles of incorporation",
        "Church covenants",
        "Church orders",
        "Codes (Jewish law)",
        "Codices (Law)",
        "Collective labor agreements",
        "Commercial arbitration agreements",
        "Concordats",
        "Consilia",
        "Constitutional amendments",
        "Constitutions",
        "Contracts",
        "Cooperative agreements",
        "Court decisions and opinions",
        "Court rules",
        "Coutumes",
        "Customary laws",
        "Custumals",
        "Deeds",
        "Executive orders",
        "Fatwas",
        "Indulgences (Canon law)",
        "Intergovernmental agreements",
        "Legal instruments",
        "Legal memorandums",
        "Legal petitions",
        "Legislative materials",
        "Messages (Official communications)",
        "Monastic constitutions",
        "Monastic rules",
        "Official gazettes",
        "Papal documents",
        "Papal encyclicals",
        "Patents",
        "Privileges and immunities",
        "Proclamations",
        "Records (Documents)",
        "Records and briefs",
        "Registers (Lists)",
        "Religious inventories",
        "Remonstrances",
        "Resolutions (Law)",
        "Responsa (Jewish law)",
        "Session laws",
        "Statutes and codes",
        "Travaux préparatoires (Treaties)",
        "Treaties",
        "Trial and arbitral proceedings",
        "Wills",
        "Writs",
        "Year books (English law reports)",
        "Autobiographical comics",
        "Autobiographical drama",
        "Autobiographical films",
        "Autobiographical television programs",
        "Autobiographies",
        "Captivity narratives",
        "Diaries",
        "Personal narratives",
        "Slave narratives",
        "Census data",
        "City directories",
        "Data sets",
        "Death registers",
        "Demographic surveys",
        "Judicial statistics",
        "Medical statistics",
        "Statistics",
        "Vital statistics",
        "Field recordings",
        "Interviews",
        "Radio interviews",
        "Business correspondence",
        "Chirographa (Personal correspondence)",
        "Love letters",
        "Pastoral letters and charges",
        "Personal correspondence",
        "Manuscripts",
        "Atlases",
        "Cartographic materials",
        "Digital maps",
        "Early maps",
        "Geospatial data",
        "Globes",
        "Gores (Maps)",
        "Manuscript maps",
        "Mappae mundi",
        "Maps",
        "Military maps",
        "Mine maps",
        "Nautical charts",
        "Outline maps",
        "Physical maps",
        "Quadrangle maps",
        "Raster data",
        "Road maps",
        "Stick charts",
        "Strip maps",
        "Topographic maps",
        "Topological maps",
        "Upside-down maps",
        "World atlases",
        "World maps",
        "Zoning maps",
        "Field notes",
        "Notebooks",
        "Sketchbooks",
        "Oral histories",
        "Personal recordings",
        "Ephemera",
        "Tracts (Ephemera)",
        "Aerial photographs",
        "Aerial views",
        "Baby books",
        "Drawings",
        "Negatives (Photographs)",
        "Photographs",
        "Pictures",
        "Portraits",
        "Selfies",
        "Self-portraits",
        "Visual works",
        "Campaign speeches",
        "Occasional speeches",
        "Speeches",
    ]
    .map(Subdivision::from)
});

fn genres_from_primary_source_lcgft_mapping(record: &Record) -> Vec<String> {
    if is_book(record) && is_literary_work(record) {
        return vec![];
    }
    if record
        .extract_fields("655")
        .filter(|field| {
            matches!(
                GenreVocabulary::from(*field),
                GenreVocabulary::LCGenreFormTerms
            )
        })
        .any(|field| {
            field
                .get_subfields("a")
                .iter()
                .any(|sf| does_lcgft_genre_term_indicate_primary_source(sf.content()))
        })
    {
        vec!["Primary sources".to_string()]
    } else {
        vec![]
    }
}

fn does_lcgft_genre_term_indicate_primary_source(value: &str) -> bool {
    let term = CombinedTerm::from(value);
    PRIMARY_SOURCE_LCGFT_GENRES
        .iter()
        .any(|lcgft_genre| term.contains(lcgft_genre))
}

fn is_literary_work(record: &Record) -> bool {
    literary_forms(record)
        .iter()
        .any(|form| form.is_literature())
}

fn is_book(record: &Record) -> bool {
    let type_of_record: Result<TypeOfRecord, _> = record.try_into();
    let bibliographic_level: Result<BibliographicLevel, _> = record.try_into();
    matches!((type_of_record, bibliographic_level), (Ok(TypeOfRecord::LanguageMaterial), Ok(level)) if !level.is_serial())
}

fn is_literary_book(record: &Record) -> bool {
    is_book(record) && is_literary_work(record)
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::marc::subject::SEPARATOR;

    #[test]
    fn it_identies_nonfiction_title_as_non_literary() {
        let record = Record::from_breaker(
            r#"=LDR 04137cam a2200853Ii 4500
=008                                  0
=650  0 $a Franco-Prussian War, 1870-1871 $v Pamphlets."#,
        )
        .unwrap();
        assert!(!is_literary_work(&record))
    }

    #[test]
    fn it_identies_fiction_title_as_literary() {
        let record = Record::from_breaker(
            r#"=LDR 04137cam a2200853Ii 4500
=008                                  1
=650  0 $a Franco-Prussian War, 1870-1871 $v Pamphlets."#,
        )
        .unwrap();
        assert!(is_literary_work(&record))
    }

    #[test]
    fn it_can_find_genres_from_subject_vocabularies() {
        let record = Record::from_breaker(
            r#"=LDR 04137cam a2200853Ii 4500
=655 \7 $a Afrofuturist comics $2 lcgft
=655 \7 $a Random genre $2 invalid thesaurus"#,
        )
        .unwrap();
        assert_eq!(
            genres_from_subject_vocabularies(&record).collect::<Vec<_>>(),
            vec!["Afrofuturist comics".to_string()]
        )
    }

    #[test]
    fn it_can_find_genres_from_630x() {
        let record = Record::from_breaker(
            r#"=600 \\$aExclude$vJohn$xJoin
=630 \0$xFiction.
=655 \\$aCulture.$xDramatic rendition$vAwesome
=655 \\$aPoetry$xTranslations into French$vMaps
=655 \\$aManuscript$xTranslations into French$vGenre$2rbgenr"#,
        )
        .unwrap();
        assert_eq!(genres_from_subfield_x(&record), vec!["Fiction"]);
    }

    #[test]
    fn it_can_identify_autobiographies_as_primary_source() {
        let record = Record::from_breaker(
            r#"=LDR 02056cam a2200385 i 4500
=008 180831s2018 ag 000 0 spa d
=100 1\ $a Barilaro, Javier, $d 1974- $e author.  $0 http://id.loc.gov/authorities/names/no2019132371
=600 10 $a Barilaro, Javier, $d 1974- $v Biography."#,
        )
        .unwrap();
        assert_eq!(
            genres(&record),
            vec!["Biography".to_string(), "Primary sources".to_string()]
        )
    }

    #[test]
    fn it_can_find_genres_from_lcgft() {
        let record = Record::from_breaker(
            r#"=LDR 04137cam a2200853Ii 4500
=655 \7 $a Chirographa (Personal correspondence) $2 lcgft"#,
        )
        .unwrap();
        assert_eq!(
            genres(&record),
            vec![
                "Chirographa (Personal correspondence)".to_string(),
                "Primary sources".to_string()
            ]
        )
    }

    #[test]
    fn it_can_identify_primary_source() {
        assert!(does_lcsh_genre_term_indicate_primary_source(
            "Correspondence"
        ));
    }

    #[test]
    fn it_creates_rbgenr_genre_facet_from_rbgenr_terms() {
        let record = Record::from_breaker(
            r"=655 \7$aAcademic addresses $z Maine $z Waterville $y 1824. $2 rbgenr",
        )
        .unwrap();
        assert_eq!(
            rbgenr_genre_facet(&record).collect::<Vec<_>>(),
            vec![
                "Academic addresses".to_string(),
                format!("Academic addresses{SEPARATOR}Maine"),
                format!("Academic addresses{SEPARATOR}Maine{SEPARATOR}Waterville"),
                format!("Academic addresses{SEPARATOR}Maine{SEPARATOR}Waterville{SEPARATOR}1824"),
            ]
        );
    }

    #[test]
    fn it_builds_rare_books_genre_facet_with_all_subdivision_levels() {
        let record = Record::from_breaker(
            r#"=655 \7 $a Dust jackets (Bindings) $y 2013. $2 rbbin
=655 \7 $a Dust jackets (Binding) $y 2013. $2 rbbin"#,
        )
        .unwrap();
        assert_eq!(
            rbgenr_genre_facet(&record).collect::<Vec<_>>(),
            vec![
                "Dust jackets (Bindings)".to_string(),
                format!("Dust jackets (Bindings){SEPARATOR}2013"),
                "Dust jackets (Binding)".to_string(),
                format!("Dust jackets (Binding){SEPARATOR}2013"),
            ]
        );
    }

    #[test]
    fn it_excludes_non_rare_books_vocabs_from_genre_facet() {
        let record = Record::from_breaker(
            r#"=655 \7 $a Picture books. $2 lcgft
=655 \7 $a Stories without words. $2 aat
=655 \7 $a Histoires sans paroles. $2 rvmgf
=655 \7 $a Rare books genre $x Subdivision $2 rbgenr"#,
        )
        .unwrap();
        assert_eq!(
            rbgenr_genre_facet(&record).collect::<Vec<_>>(),
            vec![
                "Rare books genre".to_string(),
                format!("Rare books genre{SEPARATOR}Subdivision"),
            ]
        );
    }

    #[test]
    fn it_skips_rare_books_genre_headings_without_subdivisions() {
        let record = Record::from_breaker(
            r#"=655 \7 $2 rbbin
=655 \7 $a Real heading $2 rbgenr"#,
        )
        .unwrap();
        assert_eq!(
            rbgenr_genre_facet(&record).collect::<Vec<_>>(),
            vec!["Real heading".to_string()]
        );
    }

    #[test]
    fn it_includes_non_latin_rare_books_genre_facet() {
        let record = Record::from_breaker(
            r#"=655 \7 $6880-01 $a Latin heading $2 rbgenr
=880 \7 $6655-01 $a 中文标题 $2 rbgenr"#,
        )
        .unwrap();
        assert_eq!(
            rbgenr_genre_facet(&record).collect::<Vec<_>>(),
            vec!["Latin heading".to_string(), "中文标题".to_string()]
        );
    }
}
