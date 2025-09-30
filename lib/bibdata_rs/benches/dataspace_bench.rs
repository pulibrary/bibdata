use std::{fs::File, io::BufReader};

use bibdata_rs::{
    solr::SolrDocument,
    theses::legacy_dataspace::document::{self, DataspaceDocument},
};
use criterion::{criterion_group, criterion_main, Criterion};

fn title_normalize_benchmark(c: &mut Criterion) {
    let mut group = c.benchmark_group("title_normalize");
    group.bench_function("title_search_versions", |b| {
        b.iter(|| {
            let document = document::DataspaceDocument::builder()
                .with_title("2D \\(^{1}\\)H-\\(^{14}\\)N HSQC inverse-detection experiments")
                .build();
            document.title_search_versions();
        })
    });

    group.finish();
}

fn dataspace_to_solr_benchmark(c: &mut Criterion) {
    let mut group = c.benchmark_group("solr_document_from_dataspace_document");
    group.bench_function("from", |b| {
        b.iter(|| {
            let fixture =
                File::open("../../spec/fixtures/files/theses/dsp01b2773v788.json").unwrap();
            let reader = BufReader::new(fixture);
            let documents: Vec<DataspaceDocument> = serde_json::from_reader(reader).unwrap();
            let solr_documents: Vec<SolrDocument> =
                documents.iter().map(SolrDocument::from).collect();
            assert_eq!(
                solr_documents[0].title_citation_display,
                Some("Dysfunction: A Play in One Act".to_string())
            );
        })
    });

    group.finish();
}

criterion_group!(
    valid_benches,
    title_normalize_benchmark,
    dataspace_to_solr_benchmark
);
criterion_main!(valid_benches);
