# encoding: UTF-8
require 'traject/macros/marc21_semantics'
require 'traject/macros/marc_format_classifier'
require 'traject/null_writer'
require 'bundler/setup'
require_relative './alma_reader'
require 'iso-639'

extend Traject::Macros::Marc21Semantics
extend Traject::Macros::MarcFormats

settings do
  provide "reader_class_name", "AlmaReader"
  provide "marc_source.type", "xml"
  provide "marc4j_reader.source_encoding", "UTF-8"
  provide "log.error_file", "./log/traject-extract-ids-error.log"
  provide "allow_duplicate_values", false
  provide "writer_class_name", "Traject::NullWriter"
end

$LOAD_PATH.unshift(File.expand_path('../../', __FILE__)) # include marc_to_solr directory so local translation_maps can be loaded

id_extractor = Traject::MarcExtractor.new('001', first: true)
delete_ids = Concurrent::Set.new
update_ids = Concurrent::Set.new

each_record do |record, _context|
  id = id_extractor.extract(record).first
  if record.leader[5] == 'd'
    delete_ids << id
  else
    update_ids << id
  end
end

after_processing do
  LogIdsService.save(delete_ids: delete_ids.to_a, update_ids: update_ids.to_a)
end
