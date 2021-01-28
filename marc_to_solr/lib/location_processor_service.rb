require 'pp'

class LocationProcessorService
  def self.locations
    Locations::HoldingLocation.all
  end

  def self.location_display_file_path
    Rails.root.join('marc_to_solr', 'translation_maps', 'location_display.rb')
  end

  def self.write_location_display(values)
    File.open(location_display_file_path, 'w') do |file|
      PP.pp(values, file)
    end
  end

  def self.locations_file_path
    Rails.root.join('marc_to_solr', 'translation_maps', 'locations.rb')
  end

  def self.write_locations(values)
    File.open(locations_file_path, 'w') do |file|
      PP.pp(values, file)
    end
  end

  def self.holding_library_file_path
    Rails.root.join('marc_to_solr', 'translation_maps', 'holding_library.rb')
  end

  def self.write_holding_library(values)
    File.open(holding_library_file_path, 'w') do |file|
      PP.pp(values, file)
    end
  end

  def self.location_display_processed?
    File.zero?(location_display_file_path)
  end

  def self.locations_processed?
    File.zero?(locations_file_path)
  end

  def self.holding_library_processed?
    File.zero?(holding_library_file_path)
  end

  def self.processed?
    location_display_processed?
    locations_processed?
    holding_library_processed?
  end

  def self.process
    unless holding_locations_table_exists?
      logger.warn("Failed to seed the holding locations for Traject as the database table has not been created. Please invoke bundle exec rake db:create")
      return
    end

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

    write_location_display(lib_display)
    write_locations(longer_display)
    write_holding_library(holding_library)
  end

  def self.holding_locations_table_exists?
    ActiveRecord::Base.connection.table_exists?('locations_holding_locations')
  rescue StandardError => database_error
    Rails.logger.warn("Failed to seed the holding locations for Traject due to a database error: #{database_error}.")
    false
  end

  def self.logger
    @logger ||= Rails.logger || Logger.new(STDOUT)
  end
end
