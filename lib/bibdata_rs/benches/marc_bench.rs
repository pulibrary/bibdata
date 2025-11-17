use bibdata_rs::marc::genre::genres;
use criterion::{criterion_group, criterion_main, Criterion};
use marctk::Record;

fn genre_facet_benchmark(c: &mut Criterion) {
    let record = Record::from_xml_file("../../spec/fixtures/99100026953506421.mrx")
        .unwrap()
        .next()
        .unwrap()
        .unwrap();
    c.bench_function("genres", |b| {
        b.iter(|| {
            assert_eq!(genres(&record), vec!["Periodicals", "Facsimiles"]);
        })
    });
}

criterion_group!(benches, genre_facet_benchmark);
criterion_main!(benches);
