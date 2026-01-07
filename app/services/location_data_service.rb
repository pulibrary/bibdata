class LocationDataService
  # Delete existing locations data repopulate tables with data from Alma
  def self.delete_existing_and_repopulate
    new.delete_existing_and_repopulate
  end

  def delete_existing_and_repopulate
    DeliveryLocation.delete_all
    HoldingLocation.delete_all
    Library.delete_all
    populate_libraries
    populate_delivery_locations
    populate_holding_locations
  end

  def populate_libraries
    # Populate Library model using the libraries.json file
    libraries_array.each do |library|
      Library.create(
        label: library['label'],
        code: library['code'],
        order: library['order']
      )
    end
  end

  def populate_holding_locations
    holding_locations_array.each do |holding_location|
      holding_location_record = HoldingLocation.create(
        label: holding_location['label'],
        code: holding_location['code'],
        aeon_location: holding_location['aeon_location'],
        recap_electronic_delivery_location: holding_location['recap_electronic_delivery_location'],
        open: holding_location['open'],
        requestable: holding_location['requestable'],
        always_requestable: holding_location['always_requestable'],
        circulates: holding_location['circulates'],
        remote_storage: holding_location['remote_storage'],
        fulfillment_unit: holding_location['fulfillment_unit'],
        locations_library_id: holding_location['library'] ? library_id(holding_location['library']['code']) : {},
        holding_library_id: holding_location['holding_library'] ? library_id(holding_location['holding_library']['code']) : {} # Library.where(label: holding_location["holding_library"]).first.id
      )
      holding_location_record.delivery_location_ids = delivery_library_ids(holding_location['delivery_locations'])
    end
  end

  # Populate delivery locations based on the delivery_locations.json
  # @note Do NOT remove values from here without updating Figgy appropriately.
  # The URIs are referenced in Figgy and removing them will break manifests.
  # These values will not change when we move to alma.
  def populate_delivery_locations
    highest_id = delivery_locations_array.sort_by { |x| x['id'] }.last['id']
    # Reset the auto-increment column so it starts above the highest count.
    DeliveryLocation.connection.execute("ALTER SEQUENCE locations_delivery_locations_id_seq RESTART WITH #{highest_id + 1}")
    delivery_locations_array.each do |delivery_location|
      library_record_id = find_library_by_code(delivery_location['library']['code']).id
      DeliveryLocation.create(
        id: delivery_location['id'],
        label: delivery_location['label'],
        address: delivery_location['address'],
        phone_number: delivery_location['phone_number'],
        contact_email: delivery_location['contact_email'],
        staff_only: delivery_location['staff_only'],
        locations_library_id: library_record_id,
        gfa_pickup: delivery_location['gfa_pickup'],
        pickup_location: delivery_location['pickup_location'],
        digital_location: delivery_location['digital_location']
      )
    end
  end

  private

    def library_id(holding_library_code)
      return {} unless holding_library_code

      library = find_library_by_code(holding_library_code)
      library.presence&.id
    end

    # Find the delivery library using the gfa_pickup value
    # example: gfa_pickup = ["QT", "QA", "PA", "QC"] for anxbnc
    def delivery_library_ids(gfa_pickup)
      ids = []
      gfa_pickup.each do |d|
        delivery_location = DeliveryLocation.all.find { |m| m['gfa_pickup'] == d }
        ids << delivery_location.id if delivery_location.present?
      end
      ids
    end

    # Find the library using the library code
    def find_library_by_code(code)
      Library.find_by(code:)
    end

    # Parses holding_locations.json file
    # Creates an array of holding_location hashes
    def holding_locations_array
      file = File.read(File.join(MARC_LIBERATION_CONFIG['location_files_dir'], 'holding_locations.json'))
      JSON.parse(file)
    end

    # Parses delivery_locations.json file
    # Creates an array of delivery_locations hashes
    def delivery_locations_array
      file = File.read(File.join(MARC_LIBERATION_CONFIG['location_files_dir'], 'delivery_locations.json'))
      JSON.parse(file)
    end

    # Parses libraries.json file
    # Creates an array of libraries hashes
    def libraries_array
      file = File.read(File.join(MARC_LIBERATION_CONFIG['location_files_dir'], 'libraries.json'))
      JSON.parse(file)
    end
end
