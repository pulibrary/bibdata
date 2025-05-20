use bibdata_rs::theses::dataspace::document;
use criterion::{criterion_group, criterion_main, Criterion};

fn title_normalize_benchmark(c: &mut Criterion) {
    let mut group = c.benchmark_group("title_normalize");
    group.bench_function("map", |b| {
        b.iter(|| {
            let document = document::DataspaceDocument::builder()
                .with_title("2D \\(^{1}\\)H-\\(^{14}\\)N HSQC inverse-detection experiments")
                .build();
            document.title_search_versions();
        })
    });

    group.finish();
}

criterion_group!(valid_benches, title_normalize_benchmark);
criterion_main!(valid_benches);
