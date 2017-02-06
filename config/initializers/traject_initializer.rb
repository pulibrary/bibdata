require 'pp'

def setup_indexer
  process_locations unless Rails.env.test?
  c = File.join(Rails.root, 'marc_to_solr', 'lib', 'traject_config.rb')
  indexer = Traject::Indexer.new
  indexer.load_config_file(c)
  indexer
end

def process_locations
  locations = Locations::HoldingLocation.all
  libdisplay = Hash.new
  longerdisplay = Hash.new
  locations.each do |holding|
    holding_code = holding["code"]
    lib_label = holding.library["label"]
    holding_label = holding["label"] == '' ? lib_label : lib_label + ' - ' + holding['label']
    libdisplay[holding_code] = lib_label
    longerdisplay[holding_code] = holding_label
  end
  File.open(File.expand_path('../../../marc_to_solr/translation_maps/location_display.rb', __FILE__), 'w') { |file| PP.pp(libdisplay, file) }
  File.open(File.expand_path('../../../marc_to_solr/translation_maps/locations.rb', __FILE__), 'w') { |file| PP.pp(longerdisplay, file) }
end

TRAJECT_INDEXER ||= setup_indexer
