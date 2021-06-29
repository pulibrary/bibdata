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
    stub_request(:get, "https://api-na.hosted.exlibrisgroup.com/almaws/v1/conf/libraries/eastasian/locations")
      .with(
        headers: {
          'Accept' => 'application/json',
          'Authorization' => 'apikey TESTME'
        }
      )
      .to_return(
        status: 200,
        headers: { "content-Type" => "application/json" },
        body: file_fixture("alma/locations5.json")
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
      location_record10 = Locations::HoldingLocation.find_by(code: 'eastasian$hy')

      expect(Locations::Library.count).to eq 6
      expect(Locations::HoldingLocation.count).to eq 65
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
      expect(location_record10.label).to eq ''
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
      expect(scsbcul_record.remote_storage).to eq 'recap_rmt'
      expect(scsbhl_record.remote_storage).to eq 'recap_rmt'
      expect(scsbnypl_record.remote_storage).to eq 'recap_rmt'
    end

    it "deletes existing delivery locations table and populates new from json file" do
      LocationDataService.delete_existing_and_repopulate
      library_record = Locations::Library.find_by(code: 'annex')
    end

    it "sets a static ID" do
      LocationDataService.delete_existing_and_repopulate
      # Run a second time to ensure idempotency.
      LocationDataService.delete_existing_and_repopulate

      location = Locations::DeliveryLocation.find_by(gfa_pickup: "PW")

      expect(location.id).to eq 3
      expect(location.label).to eq "Architecture Library"
      new_location = FactoryBot.create(:delivery_location)
      expect(new_location.id).to eq 41
    end
  end

  def delivery_location_record(value)
    Locations::DeliveryLocation.all.find(value.delivery_location_ids.first)
  end
end
