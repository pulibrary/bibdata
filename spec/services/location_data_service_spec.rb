require 'rails_helper'

RSpec.describe LocationDataService, type: :service do
  subject(:service) { described_class.new }

  before do
    stub_request(:get, "https://api-na.hosted.exlibrisgroup.com/almaws/v1/conf/libraries")
      .with(
        headers: {
          'Accept' => 'application/json',
          'Authorization' => 'apikey TESTME'
        }
      )
      .to_return(
        status: 200,
        headers: { "content-Type" => "application/json" },
        body: file_fixture("alma/libraries.json")
      )

    stub_request(:get, "https://api-na.hosted.exlibrisgroup.com/almaws/v1/conf/libraries/arch/locations")
      .with(
        headers: {
          'Accept' => 'application/json',
          'Authorization' => 'apikey TESTME'
        }
      )
      .to_return(
        status: 200,
        headers: { "content-Type" => "application/json" },
        body: file_fixture("alma/locations1.json")
      )

    stub_request(:get, "https://api-na.hosted.exlibrisgroup.com/almaws/v1/conf/libraries/annex/locations")
      .with(
        headers: {
          'Accept' => 'application/json',
          'Authorization' => 'apikey TESTME'
        }
      )
      .to_return(
        status: 200,
        headers: { "content-Type" => "application/json" },
        body: file_fixture("alma/locations2.json")
      )
  end

  describe "#delete_existing_and_repopulate" do
    before do
      # Setup fake records to test if existing records are deleted
      test_library = Locations::Library.create(code: 'test', label: 'test')
      Locations::HoldingLocation.new(code: 'test', label: 'test') do |test_location|
        test_location.library = test_library
        test_location.save
      end
      Locations::DeliveryLocation.new(label: 'test', address: 'test') do |_test_location|
        test_delivery_location.library = test_library
        test_delivery_location.save
      end
    end

    # delivery_record.label = delivery_location['label']
    # delivery_record.address = delivery_location['address']
    # delivery_record.phone_number = delivery_location['phone_number']
    # delivery_record.contact_email = delivery_location['contact_email']
    # delivery_record.staff_only =  delivery_location['staff_only']
    # delivery_record.library = library_record
    # delivery_record.gfa_pickup = delivery_location['gfa_pickup']
    # delivery_record.pickup_location = delivery_location['pickup_location']
    # delivery_record.digital_location = delivery_location['digital_location']

    it "deletes existing data and populates library and location data from Alma" do
      LocationDataService.delete_existing_and_repopulate
      library_record = Locations::Library.find_by(code: 'arch')
      location_record1 = Locations::HoldingLocation.find_by(code: 'arch$stacks')
      location_record2 = Locations::HoldingLocation.find_by(code: 'annex$stacks')

      expect(Locations::Library.count).to eq 2
      expect(Locations::HoldingLocation.count).to eq 26
      expect(library_record.label).to eq 'Architecture Library'
      expect(location_record2.label).to eq 'Forrestal Annex - Annex Stacks'
      expect(location_record1.open).to be true
      expect(location_record2.open).to be false
    end

    it "deletes existing delivery locations table and populates new from json file" do
      LocationDataService.delete_existing_and_repopulate
      library_record = Locations::Library.find_by(code: 'annex')
      expect(library_record.delivery_location_ids).to eq []
    end
  end
end
