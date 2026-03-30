use figgy_marc::{FiggyMarcConfig, fetch_report, only_open};
use std::env;

fn main() {
    let config =
        FiggyMarcConfig::try_new(env::var).expect("Could not determine the correct configuration");
    let all_records = fetch_report(&config).expect("Could not fetch report from Figgy");
    let only_open = only_open(&all_records);
    println!(
        "Got {} records from Figgy, {} of them have open",
        all_records.len(),
        only_open.len()
    );
}
