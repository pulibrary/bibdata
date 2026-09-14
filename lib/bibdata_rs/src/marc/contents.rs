use crate::marc::variable_length_field::extract_marc;
use marctk::Record;

pub fn table_of_contents(record: &Record) -> Vec<String> {
    extract_marc!("505agrt")(record)
        .iter()
        .flat_map(|contents| contents.split(" -- "))
        .map(ToString::to_string)
        .collect()
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn it_gets_contents_from_a_505_with_a_single_a_subfield() {
        let record = Record::from_breaker(r#"=505 0\$aIntroduction -- My Tennessee mountain home -- Down on Music Row -- Porter Wayne and Dolly Rebecca -- Putting wings on my dreams -- Golden streets of glory -- Bubbling over -- They're singing my songs -- Light of a clear blue morning -- Working 9 to 5 -- Eagle when she flies -- Hungry again -- The grass is blue -- Me, an "icon"? -- Better days."#).unwrap();
        let contents = table_of_contents(&record);
        assert_eq!(
            contents
                .iter()
                .map(|content| content.as_str())
                .collect::<Vec<_>>(),
            [
                "Introduction",
                "My Tennessee mountain home",
                "Down on Music Row",
                "Porter Wayne and Dolly Rebecca",
                "Putting wings on my dreams",
                "Golden streets of glory",
                "Bubbling over",
                "They're singing my songs",
                "Light of a clear blue morning",
                "Working 9 to 5",
                "Eagle when she flies",
                "Hungry again",
                "The grass is blue",
                r#"Me, an "icon"?"#,
                "Better days."
            ]
        )
    }

    #[test]
    fn it_gets_contents_from_a_combination_of_505t_r_and_g() {
        let record = Record::from_breaker(r#"=505 0\$t Four in one $g (3:28) -- $t Criss cross $g (2:54) -- $t Eronel / $r Monk, Sulieman, Hakim $g (3:02) -- $t Straight no chaser $g (2:56) -- $t Ask me now $g (3:13) -- $t Willow weep for me / $r Ann Ronnell $g (2:58)"#).unwrap();
        let contents = table_of_contents(&record);
        assert_eq!(
            contents
                .iter()
                .map(|content| content.as_str())
                .collect::<Vec<_>>(),
            vec![
                "Four in one (3:28)",
                "Criss cross (2:54)",
                "Eronel / Monk, Sulieman, Hakim (3:02)",
                "Straight no chaser (2:56)",
                "Ask me now (3:13)",
                "Willow weep for me / Ann Ronnell (2:58)"
            ]
        );
    }
}
