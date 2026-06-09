# Agents Guide for Bibdata

This application is a middleware that supports the Princeton University Library Catalog by:
* Indexing records from various sources into Solr for searching.  See docs/indexing.md
  for more information about the various record sources.
* Providing data from Alma and SCSB systems about the real-time
  availability of items in the catalog.

## Rust migration

We are currently migrating the indexing code from Ruby (using the traject gem) to Rust
(using the marctk crate to handle MARC parsing), with goals of increasing performance
and throughput.  The Rust code for indexing can mainly be found at lib/bibdata_rs.

We use the magnus crate to make Rust code available in Ruby.  See
lib/bibdata_rs/src/marc/ruby_bindings.rs for an example of how the bindings work.
To reduce the overhead of passing data between Rust and Ruby, much of the binding is
centralized in a single method (BibdataRs::Marc.solr_fields), which returns a Ruby
hash of SOLR fields and values and is made available
in traject_config.rb as context.clipboard[:solr_fields].

### Best practices when migrating logic from Ruby to Rust

* Ensure that the Ruby tests keep passing (`bundle exec rspec spec/marc_to_solr`)
* Add rust unit tests.  Make sure they pass with `cargo test`
    * Match the style of existing tests as much as possible.
    * When testing the MARC logic, prefer creating MARC records using the
    [MarcBreaker](https://www.loc.gov/marc/makrbrkr.html) format.
    * If the ruby binding requires special attention, write a test for it in Rust
      using the rb_sys `ruby_test` macro.
* Format with `cargo fmt`
* Run clippy with `cargo clippy`
* For complex or computationally intensive logic, add a benchmark that exercises
  the new logic in lib/bibdata_rs/benches so that
  we have a starting place when doing future performance work.  Make sure that it
  runs with `cargo bench`

## Processing MARC records

Most data in our Solr index comes from [MARC bibliographic records](https://www.loc.gov/marc/bibliographic/)
(also known as bib records).

### Specifics of our MARC records:

* Materials owned by Princeton and managed in the Alma system have an ID known as MMS ID that begins with 99 and
  ends with 421
* Materials owned by partner libraries have an id beginning with SCSB-

### Common pitfalls when processing MARC records:

* MARC data field subfields often contain preceding and trailing space/punctuation to adhere to
  ISBD formatting (or other formatting) standards.  Be careful of this when doing string comparisons.
* Do not rely on Rails or Activesupport in `marc_to_solr`, they are not required in this directory.
  Use standard Ruby.
