# Bibdata

Local API for retrieving bibliographic and other useful data from Alma.

[![CircleCI](https://circleci.com/gh/pulibrary/bibdata.svg?style=svg)](https://circleci.com/gh/pulibrary/bibdata)
[![CoverageStatus](https://coveralls.io/repos/github/pulibrary/bibdata/badge.svg?branch=main)](https://coveralls.io/github/pulibrary/bibdata?branch=main)
[![BSD 2-Clause License](https://img.shields.io/badge/license-BSD-blue.svg?style=plastic)](./LICENSE)

Find Internal Documentation on our [confluence
wiki](https://pul-confluence.atlassian.net/wiki/spaces/ALMA/overview)

## Development and testing

### Dependencies
  * Postgresql (provided in development by lando)
  * `brew install lastpass-cli`
  * `brew install shared-mime-info` (for `mimemagic` gem)

Note: You need to have PostgreSQL installed in your machine and available in your path for the `pg` gem to compile native extensions (e.g. `export PATH=$PATH:/Library/PostgreSQL/10/bin/`).

### Setup server
1. Install Lando from [lando releases GitHub](https://github.com/lando/lando/releases) (at least 3.0.0-rrc.2)
1. Install Sidekiq Pro credentials:
```
lpass login emailhere
bin/setup_keys
```
1. Install bundler version in Gemfile.lock
```
gem install bundler -v '2.2.27'
```
1. Install bundle
```
bundle install
```
1. To start: `bundle exec rake servers:start`
1. For testing:
   - `bundle exec rspec`
1. For development:
   - `bundle exec rails server`
   - Access bibdata at http://localhost:3000/
   - If you will be working with background jobs in development, include your netid so you are recognized as an admin `BIBDATA_ADMIN_NETIDS=yournetid bundle exec rails server`
1. If you are working with background jobs in development, start sidekiq in a new tab or window
   - `bundle exec sidekiq`
   - To access the sidekiq dashboard, first sign into the application, then go to http://localhost:3000/sidekiq
1. To stop: `bundle exec rake servers:stop` or `lando stop`

## Configure Alma keys for Development

1. `lpass login emailhere`
1. `bundle exec rake alma:setup_keys`

This will add a .env with credentials to Rails.root

## ARK Caching

In order to resolve bibliographic identifiers (bib. IDs) to resources with ARKs and IIIF manifests for resources managed within digital repositories, caches are seeded and used in order to resolve the relationships between these resources.

### Seeding the Cache

One may seed the cache using the following Rake Task:
```bash
rake liberate:arks:seed_cache
```

In development, when running commands that utilize the cache, such as commands indexing via traject, set the `FIGGY_ARK_CACHE_PATH` to point to `spec/fixtures/marc_to_solr/figgy_ark_cache` in the local environment.
```bash
export FIGGY_ARK_CACHE_PATH=spec/fixtures/marc_to_solr/figgy_ark_cache
```

### Clearing the Cache

One may clear the cache using the following Rake Task:
```bash
rake liberate:arks:clear_cache
```


## Tests

Ensure redis is running

To run the tests in the `marc_to_solr` directory set RAILS_ENV:
`$ RAILS_ENV=test bundle exec rspec spec/marc_to_solr`

To run all the tests use the rake task, which sets some environment variables for you:
`$ rake spec`

Run Rust tests with `cargo test`.

### Benchmarking and profiling

Run Rust benchmarks with `cargo bench`.

Profiling the rust code can be a little tricky, since if you try to profile it from a
ruby entrypoint, the rust code will have been compiled with optimizations that
mean you can't see the names of functions, etc.  However, due to the Magnus integration,
it can be hard to try to run the rust code in isolation without a Ruby VM.

Given the above challenges, one approach to profiling is:
1. Write a criterion benchmark for the code you want to profile.
2. Install samply: `cargo install --locked samply`
3. Assuming you want to profile the marc_bench benchmark: `samply record cargo bench --bench marc_bench --profile=profiling -- --profile-time 5`
4. Samply will open up the Firefox profiler with the results.  Note that samply also profiles the rust compiler, so if your results are filled with `rustc`, you can remove those tracks (or simply re-run the previous `samply` command) to remove those distractions.
5. The Flame Graph and Stack Chart tabs within the Firefox profiler are the most useful.

## Compiling

Some business logic is written in Rust.  This code is compiled when you
do any of the following actions:
* deploy
* run an rspec test with the `rust` tag
* call a class, module, or method that is provided by the Rust code and there is no
  existing binary
* run `bundle exec rake compile`

## Semgrep

This repository uses [semgrep](https://semgrep.dev/) to:

* Guard against common gotchas within bibdata
* Perform static security analysis

To run semgrep locally:

```
brew install semgrep
semgrep --config .semgrep.yml . # run custom bibdata rules
semgrep --config auto . # run rules from the semgrep community
semgrep --config auto --config .semgrep.yml . # run both sets of rules
```

## Deploy
Deployment is through capistrano. To deploy a branch other than "main", prepend an environment variable to your deploy command, e.g.:
`BRANCH=my_feature bundle exec cap staging deploy`

## Locations Configuration

See: [Location Changes documentation](https://github.com/pulibrary/bibdata/blob/main/docs/location_changes.md)

## API Endpoints
[API Endpoint documentation](docs/api_endpoints.md)

## Alma Webhooks
see [[webhook_monitor/README.md]]

## License

See `LICENSE`.
