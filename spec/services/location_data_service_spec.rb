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

    stub_request(:get, "https://api-na.hosted.exlibrisgroup.com/almaws/v1/conf/libraries/firestone/locations")
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
    stub_request(:get, "https://api-na.hosted.exlibrisgroup.com/almaws/v1/conf/libraries/online/locations")
      .with(
        headers: {
          'Accept' => 'application/json',
          'Authorization' => 'apikey TESTME'
        }
      )
      .to_return(
        status: 200,
        headers: { "content-Type" => "application/json" },
        body: file_fixture("alma/locations3.json")
      )
    stub_request(:get, "https://api-na.hosted.exlibrisgroup.com/almaws/v1/conf/libraries/recap/locations")
      .with(
        headers: {
          'Accept' => 'application/json',
          'Authorization' => 'apikey TESTME'
        }
      )
      .to_return(
        status: 200,
        headers: { "content-Type" => "application/json" },
        body: file_fixture("alma/locations4.json")
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
      Locations::DeliveryLocation.new(label: 'test', address: 'test') do |test_delivery_location|
        test_delivery_location.library = test_library
        test_delivery_location.save
      end
    end
    let(:firestone_library) { Locations::Library.find_by(code: 'firestone') }
    let(:scsb_delivery_location) do
      Locations::DeliveryLocation.create("label": "Firestone Circulation Desk",
                                         "address": "One Washington Rd. Princeton, NJ 08544",
                                         "phone_number": "609 258-2345",
                                         "contact_email": "fstcirc@princton.edu",
                                         "gfa_pickup": "QX",
                                         "staff_only": false,
                                         "pickup_location": false,
                                         "digital_location": false,
                                         "library": firestone_library)
    end

    it "deletes existing data and populates library and location data from Alma excluding elfs" do
      LocationDataService.delete_existing_and_repopulate
      library_record = Locations::Library.find_by(code: 'arch')
      location_record1 = Locations::HoldingLocation.find_by(code: 'arch$stacks')
      location_record2 = Locations::HoldingLocation.find_by(code: 'annex$stacks')
      location_record3 = Locations::HoldingLocation.find_by(code: 'online$elf1')
      location_record4 = Locations::HoldingLocation.find_by(code: 'online$elf2')
      location_record5 = Locations::HoldingLocation.find_by(code: 'online$elf3')
      location_record6 = Locations::HoldingLocation.find_by(code: 'online$elf4')
      location_record7 = Locations::HoldingLocation.find_by(code: 'online$cdl')
      location_record8 = Locations::HoldingLocation.find_by(code: 'recap$gp')
      location_record9 = Locations::HoldingLocation.find_by(code: 'recap$pb')

      expect(Locations::Library.count).to eq 5
      expect(Locations::HoldingLocation.count).to eq 47
      expect(library_record.label).to eq 'Architecture Library'
      expect(location_record2.label).to eq 'Annex Stacks'
      expect(location_record1.open).to be true
      expect(location_record2.open).to be false
      expect(location_record3).to be nil
      expect(location_record4).to be nil
      expect(location_record5).to be nil
      expect(location_record6).to be nil
      expect(location_record7.code).to eq 'online$cdl'
      expect(location_record8.remote_storage).to eq 'recap_rmt'
      expect(location_record9.remote_storage).to eq ''
    end

    it "creates scsb locations" do
      LocationDataService.delete_existing_and_repopulate
      scsbnypl_record = Locations::HoldingLocation.find_by(code: 'scsbnypl')
      scsbhl_record = Locations::HoldingLocation.find_by(code: 'scsbhl')
      scsbcul_record = Locations::HoldingLocation.find_by(code: 'scsbcul')
      delivery_location_scsbcul = Locations::DeliveryLocation.all.find(scsbcul_record.delivery_location_ids.first)
      delivery_location_scsbhl = Locations::DeliveryLocation.all.find(scsbhl_record.delivery_location_ids.first)
      delivery_location_scsbnypl = Locations::DeliveryLocation.all.find(scsbnypl_record.delivery_location_ids.first)

      expect(delivery_location_record(scsbnypl_record).label).to eq 'Firestone Circulation Desk'
      expect(delivery_location_record(scsbnypl_record).gfa_pickup).to eq 'QX'
      expect(delivery_location_record(scsbhl_record).label).to eq 'Firestone Circulation Desk'
      expect(delivery_location_record(scsbcul_record).label).to eq 'Firestone Circulation Desk'
      expect(scsbcul_record.recap_electronic_delivery_location).to be true
    end

    it "deletes existing delivery locations table and populates new from json file" do
      LocationDataService.delete_existing_and_repopulate
      library_record = Locations::Library.find_by(code: 'annex')
    end
  end

  def delivery_location_record(value)
    Locations::DeliveryLocation.all.find(value.delivery_location_ids.first)
  end
end
