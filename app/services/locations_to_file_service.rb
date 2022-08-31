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
    holding_locations_json_array = JSON.generate(update_holding_locations)
    holding_locations_file = File.open(File.join(base_path, "holding_locations.json"), "w")
    holding_locations_file.write(holding_locations_json_array)
    holding_locations_file.close
  end

  # Writes a json file with delivery locations
  def delivery_locations_to_file
    delivery_locations_json_array = JSON.generate(retrieve_delivery_locations)
    delivery_locations_file = File.open(File.join(base_path, "delivery_locations.json"), "w")
    delivery_locations_file.write(delivery_locations_json_array)
    delivery_locations_file.close
  end

  def libraries_to_file
    libraries_json_array = JSON.generate(retrieve_libraries)
    libraries_file = File.open(File.join(base_path, "libraries.json"), "w")
    libraries_file.write(libraries_json_array)
    libraries_file.close
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

  def retrieve_libraries
    conn = Faraday.new(url: 'https://bibdata.princeton.edu/locations/libraries.json')
    resp = conn.get do |req|
      req.options.open_timeout = 5
    end
    libraries = resp.body
    JSON.parse(libraries)
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

  def update_holding_locations
    retrieve_holding_locations.each do |location|
      sliced_holding_delivery = retrieve_holding_delivery_location(location["code"]).slice("holding_library", "delivery_locations")
      location["holding_library"] = sliced_holding_delivery.fetch("holding_library")
      location["delivery_locations"] = sliced_holding_delivery.fetch("delivery_locations").map { |m| m["gfa_pickup"] }
    end
  end
end
