use bibdata_rs::{
    marc::{call_number::call_number_labels_for_display, genre::genres},
    solr::AuthorRoles,
};
use criterion::{Criterion, criterion_group, criterion_main};
use marctk::Record;

fn author_role_benchmark(c: &mut Criterion) {
    let record = Record::from_xml_file("../../spec/fixtures/99100026953506421.mrx")
        .unwrap()
        .next()
        .unwrap()
        .unwrap();
    let expected = AuthorRoles {
        editors: vec!["Nakanishi, Naoki".to_string()],
        ..Default::default()
    };
    c.bench_function("author_roles", |b| {
        b.iter(|| {
            assert_eq!(AuthorRoles::from(&record), expected);
        })
    });
}

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

criterion_group!(
    benches,
    author_role_benchmark,
    call_number_benchmark,
    genre_facet_benchmark
);
criterion_main!(benches);
