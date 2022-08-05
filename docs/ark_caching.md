# ARK Caching

In order to resolve bibliographic identifiers (bib. IDs) to resources with ARKs and IIIF manifests for resources managed within digital repositories, caches are seeded and used in order to resolve the relationships between these resources.

## Seeding the Cache

One may seed the cache using the following Rake Task:
```bash
rake liberate:arks:seed_cache
```

In development, when running commands that utilize the cache, such as commands indexing via traject, set the `FIGGY_ARK_CACHE_PATH` to point to `spec/fixtures/marc_to_solr/figgy_ark_cache` in the local environment.
```bash
export FIGGY_ARK_CACHE_PATH=spec/fixtures/marc_to_solr/figgy_ark_cache
```

## Clearing the Cache

One may clear the cache using the following Rake Task:
```bash
rake liberate:arks:clear_cache
```
