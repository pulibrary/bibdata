# encoding: UTF-8
# Traject config goes here
require 'traject/macros/marc21_semantics'
require 'traject/macros/marc_format_classifier'
require 'bundler/setup'

extend Traject::Macros::Marc21Semantics
extend Traject::Macros::MarcFormats

settings do
  provide "solr.url", "http://localhost:8983/solr/blacklight-core-development" # default
  provide "solr.version", "7.1.0"
  provide "marc_source.type", "binary"
  provide "solr_writer.max_skipped", "50"
  provide "marc4j_reader.source_encoding", "UTF-8"
  provide "log.error_file", "./log/traject-error.log"
  provide "allow_duplicate_values",  false
  provide "solr_writer.commit_on_close", "true"
end

$LOAD_PATH.unshift(File.expand_path('../../', __FILE__)) # include marc_to_solr directory so local translation_maps can be loaded

to_field 'id', extract_marc('001', first: true)

to_field 'marc_display', serialized_marc(:format => 'xml', :binary_escape => false, :allow_oversized => true)

to_field 'name_s', extract_marc('100:110:111')
