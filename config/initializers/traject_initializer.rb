require 'pp'

def setup_indexer
  process_locations unless Rails.env.test? || !ActiveRecord::Base.connection.table_exists?('locations_holding_locations')

  c = File.join(Rails.root, 'marc_to_solr', 'lib', 'traject_config.rb')
  indexer = Traject::Indexer.new
  indexer.load_config_file(c)
  indexer
rescue PG::Error => database_error
  Rails.logger.warn("Failed to seed the holding locations for Traject due to a database error: #{database_error}.")
rescue StandardError => error
  Rails.logger.warn("Failed to seed the holding locations for Traject: #{error}.")
end

def process_locations
  locations = Locations::HoldingLocation.all
  lib_display = {}
  longer_display = {}
  holding_library = {}
  locations.each do |holding|
    holding_code = holding['code']
    lib_label = holding.library['label']
    holding_label = holding['label'] == '' ? lib_label : lib_label + ' - ' + holding['label']
    lib_display[holding_code] = lib_label
    longer_display[holding_code] = holding_label
    holding_library[holding_code] = holding.holding_library['label'] if holding.holding_library
  end
  File.open(File.expand_path('../../../marc_to_solr/translation_maps/location_display.rb', __FILE__), 'w') { |file| PP.pp(lib_display, file) }
  File.open(File.expand_path('../../../marc_to_solr/translation_maps/locations.rb', __FILE__), 'w') { |file| PP.pp(longer_display, file) }
  File.open(File.expand_path('../../../marc_to_solr/translation_maps/holding_library.rb', __FILE__), 'w') { |file| PP.pp(holding_library, file) }
end

TRAJECT_INDEXER ||= setup_indexer
