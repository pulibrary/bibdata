use bibdata_rs::marc::{call_number::call_number_labels_for_display, genre::genres};
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

fn call_number_benchmark(c: &mut Criterion) {
    let record = Record::from_xml_file("../../spec/fixtures/99100026953506421.mrx")
        .unwrap()
        .next()
        .unwrap()
        .unwrap();
    c.bench_function("call_number_labels_for_display", |b| {
        b.iter(|| {
            assert_eq!(
                call_number_labels_for_display(&record),
                vec!["BQ8712.9.J3 Z35 2016"]
            );
        })
    });
}

criterion_group!(benches, genre_facet_benchmark, call_number_benchmark);
criterion_main!(benches);
