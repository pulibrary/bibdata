class LocationsToFileService
  def self.call
    new.holding_locations_to_file
    new.delivery_locations_to_file
  end

  attr_reader :base_path
  def initialize(base_path: Rails.root.join('config', 'locations'))
    FileUtils.mkdir_p base_path
    @base_path = base_path
  end

  # Writes a json file with holding locations.
  def holding_locations_to_file
    holding_locations_json_array = JSON.generate(alma_voyager_mapped_locations)
    holding_locations_file = File.open(File.join(base_path, "holding_locations.json"), "w")
    holding_locations_file.write(holding_locations_json_array)
    holding_locations_file.close
  end

  # Writes a json file with delivery locations
  def delivery_locations_to_file
    delivery_locations_json_array = JSON.generate(delivery_holding_locations)
    delivery_locations_file = File.open(File.join(base_path, "delivery_locations.json"), "w")
    delivery_locations_file.write(delivery_locations_json_array)
    delivery_locations_file.close
  end

  # Returns an Array of Hashes with holding locations.
  def retrieve_holding_locations
    conn = Faraday.new(url: 'https://bibdata.princeton.edu/locations/holding_locations.json')
    resp = conn.get do |req|
      req.options.open_timeout = 5
    end
    holding_locations = resp.body
    JSON.parse(holding_locations)
  end

  # Returns an Array of Hashes with delivery locations
  def retrieve_delivery_locations
    conn = Faraday.new(url: 'https://bibdata.princeton.edu/locations/delivery_locations.json')
    resp = conn.get do |req|
      req.options.open_timeout = 5
    end
    delivery_locations = resp.body
    JSON.parse(delivery_locations)
  end

  # Returns a json for the holding_location code
  def retrieve_holding_delivery_location(code)
    conn = Faraday.new(url: "https://bibdata.princeton.edu/locations/holding_locations/#{code}.json")
    resp = conn.get do |req|
      req.options.open_timeout = 5
    end
    holding_delivery_location = resp.body
    JSON.parse(holding_delivery_location)
  end

  # Use holding_locations.json to add 'alma_library_code' in the delivery locations
  def delivery_holding_locations
    retrieve_delivery_locations.each do |location|
      holding_location = holding_locations_array.find { |holding| holding['library']['code'] == location['library']['code'] }
      location["alma_library_code"] = holding_location['alma_library_code'] if holding_location.present?
    end
  end

  # Use alma_voyager_mapping.csv to map alma to voyager
  # Remove this when we move to Alma and we no longer need Voyager
  def alma_voyager_mapped_locations
    retrieve_holding_locations.each do |location|
      alma_voyager_mapping_row = alma_voyager_mapping.find { |row| row['voyager_location_code'] == location["code"] }
      location["alma_library_code"] = alma_voyager_mapping_row[1] if alma_voyager_mapping_row.present?
      location["holding_location_code"] = "#{alma_voyager_mapping_row[1]}$#{alma_voyager_mapping_row[2]}" if alma_voyager_mapping_row.present?
      sliced_holding_delivery = retrieve_holding_delivery_location(location["code"]).slice("holding_library", "delivery_locations")
      location["holding_library"] = sliced_holding_delivery.fetch("holding_library")
      location["delivery_locations"] = sliced_holding_delivery.fetch("delivery_locations").map { |m| m["gfa_pickup"] }
    end
  end

  # If there is a change in the way we map voyager to alma,
  # EUS team will provide a new voyager_alma_mapping.csv file.
  # Remove this when we move to Alma and we no longer need Voyager
  def alma_voyager_mapping
    CSV.parse(File.read("voyager_alma_mapping.csv"), headers: true)
  end

  # Parses holding_locations.json file
  # Creates an array of holding_location hashes
  def holding_locations_array
    file = File.read(File.join(base_path, "holding_locations.json"))
    JSON.parse(file)
  end

  # Parses delivery_locations.json file
  # Creates an array of delivery_locations hashes
  def delivery_locations_array
    file = File.read(File.join(base_path, "delivery_locations.json"))
    JSON.parse(file)
  end
end
