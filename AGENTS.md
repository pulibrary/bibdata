# Agents Guide for Bibdata

This application is a middleware that supports the [Princeton University Library Catalog](https://catalog.princeton.edu) by:
* Indexing records from Alma, SCSB, Figgy, DataSpace, and Thesis Central into Solr for searching.  See docs/indexing.md
  for more information about the record sources.
* Providing data from Alma and SCSB systems about the real-time
  availability of items in the catalog.

Do not modify or read the file .env.

## Rust migration

We are currently migrating the indexing code from Ruby (using the traject gem) to Rust
(using the marctk crate to handle MARC parsing), with goals of increasing performance
and throughput.  The Rust indexing code is mostly in the `REPO_ROOT/lib/bibdata_rs` directory.

The traject configuration is at `REPO_ROOT/marc_to_solr/lib/traject_config.rb`.

We use the magnus crate to make Rust code available in Ruby.  See
`REPO_ROOT/lib/bibdata_rs/src/marc/ruby_bindings.rs` for an example of how the bindings work.
Much of the binding is
centralized in a single method (BibdataRs::Marc.solr_fields), which returns a Ruby
hash of Solr fields.  `REPO_ROOT/marc_to_solr/lib/traject_config.rb` makes BibdataRs::Marc.solr_fields
available as context.clipboard[:solr_fields].

### Best practices when migrating logic from Ruby to Rust

* Ensure that the Ruby tests keep passing (`bundle exec rspec spec/marc_to_solr`)
  * Test fixtures are in `REPO_ROOT/spec/fixtures/marc_to_solr/*.mrx`.  Note that these are in the
  [MarcXML](https://www.loc.gov/standards/marcxml/) format, rather than in MarcBreaker
  format (which is used in most Rust tests). Example of MarcXML:

    ```
    <?xml version="1.0" encoding="UTF-8"?>
    <collection xmlns="http://www.loc.gov/MARC21/slim">
      <record>
        <datafield tag="245" ind1="1" ind2="0">
          <subfield code="a">Arithmetic /</subfield>
          <subfield code="c">Carl Sandburg ; illustrated as an anamorphic adventure by Ted Rand.</subfield>
        </datafield>
      </record>
    </collection>
    ```

  * The test file `REPO_ROOT/spec/marc_to_solr/lib/config_spec.rb` is a large file with many examples.
* Add rust unit tests.  Make sure they pass with `bundle install && cargo test`
    * Match the style of existing tests.
    * When testing the MARC logic, prefer creating MARC records using the
    [MarcBreaker](https://www.loc.gov/marc/makrbrkr.html) format. Example of MarcBreaker:

    ```
    =245 10$aArithmetic /$cCarl Sandburg ; illustrated as an anamorphic adventure by Ted Rand.
    ```

* Format with `cargo fmt`
* Run clippy with `cargo clippy`
* For complex logic or hot paths, add a benchmark
  to `REPO_ROOT/lib/bibdata_rs/benches`. Run the benchmark with `cargo bench`.

## Processing MARC records

Most data in our Solr index comes from [MARC bibliographic records](https://www.loc.gov/marc/bibliographic/)
(also known as bib records).

* MARC records have a leader and fields.
* MARC fields have a tag: a 3-digit number.
* MARC fields 001-009 are control fields.  They have no indicators or subfield codes.
* The leader and control fields are known as "fixed fields".  They are a fixed length
  and characters in the fields have specific meanings based on their position.
    * Specific positions have abbreviated names.  For example, `DtSt` refers to
    "Type of Date/Publication Status", which is in field 008 in position 6.
* All other fields are known as variable length fields. They have indicators and subfields.

### Specifics of our MARC records:

* Materials owned by Princeton and managed in the Alma system have an ID known as MMS ID that begins with 99 and
  ends with 421
* Materials owned by partner libraries have an id beginning with SCSB-

### Common pitfalls when processing MARC records:

* MARC data field subfields often contain preceding and trailing space/punctuation to adhere to
  ISBD formatting (or other formatting) standards.  Be careful of this when doing string comparisons.
* Most MARC data fields should only contain Latin script content.  Content in non-Latin scripts
  can be found in a parallel 880 field that is connected via subfield $6.  Index data from 880 and
  the Latin equivalent field unless otherwise specified. The
  parallel non-Latin field is sometimes called "vernacular" or "alternate script" in
  traject.
* Some MARC fields (notably 245) have non-filing characters.  When processing field 245 in Rust for the
  purposes of title sorting, use marctk `field.ind2()`  to get the count of leading non-filing characters
  (as a string), then parse and skip that many UTF-8 chars with `chars().skip(count)`.  For display, we
  should not skip non-filing characters.
* Do not rely on Rails or Activesupport in `marc_to_solr`, they are not required in this directory.
  Use standard Ruby.

## Rust standards

* When creating a new module, don't call the file mod.rs.
  * Bad filename: `lib/bibdata_rs/src/marc/frbr/mod.rs`
  * Good filename: `lib/bibdata_rs/src/marc/frbr.rs`

## Solr schema

The solr schema is in `REPO_ROOT/solr/conf/schema.xml`.  Naming conventions:

* Fields ending in _display are stored
* Fields ending in _index are for search, not display
* Fields starting with cjk_ are for search of Chinese, Japanese, and
  Korean text.  This is computationally expensive, do not add non-CJK
  text to these fields.
