use figgy_marc::{FiggyConfig, fetch_report, only_open, redis_cache};
use std::env;

fn main() {
    let config =
        FiggyConfig::try_new(env::var).expect("Could not determine the correct configuration");
    let all_records = fetch_report(&config).expect("Could not fetch report from Figgy");
    let only_open = only_open(&all_records);
    redis_cache::write(&only_open);
    println!(
        "Cached {} records from Figgy out of {} total records",
        only_open.len(),
        all_records.len(),
    );
}
