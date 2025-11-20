use bibdata_rs::languages;
use criterion::{criterion_group, criterion_main, Criterion};

fn macrolanguage_codes(c: &mut Criterion) {
    let mut group = c.benchmark_group("macrolanguage_codes");
    group.bench_function("with a language code near the start of the alphabet", |b| {
        b.iter(|| assert_eq!(languages::macrolanguage_codes("arz"), ["ara"]));
    });
    group.bench_function("with a language code near the end of the alphabet", |b| {
        b.iter(|| assert_eq!(languages::macrolanguage_codes("wuu"), ["zho", "chi"]));
    });
    group.bench_function("with a language code with no macrolanguage", |b| {
        b.iter(|| assert!(languages::macrolanguage_codes("fra").is_empty()));
    });
}

criterion_group!(benches, macrolanguage_codes);
criterion_main!(benches);
