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
        body: file_fixture("alma/locations_firestone.json")
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
        body: file_fixture("alma/locations_arch.json")
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
        body: file_fixture("alma/locations_annex.json")
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
        body: file_fixture("alma/locations_online.json")
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
        body: file_fixture("alma/locations_recap.json")
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
        body: file_fixture("alma/locations_eastasian.json")
      )
    stub_request(:get, "https://api-na.hosted.exlibrisgroup.com/almaws/v1/conf/libraries/engineer/locations")
      .with(
        headers: {
          'Accept' => 'application/json',
          'Authorization' => 'apikey TESTME'
        }
      )
      .to_return(
        status: 200,
        headers: { "content-Type" => "application/json" },
        body: file_fixture("alma/locations_engineer.json")
      )
    stub_request(:get, "https://api-na.hosted.exlibrisgroup.com/almaws/v1/conf/libraries/lewis/locations")
      .with(
        headers: {
          'Accept' => 'application/json',
          'Authorization' => 'apikey TESTME'
        }
      )
      .to_return(
        status: 200,
        headers: { "content-Type" => "application/json" },
        body: file_fixture("alma/locations_lewis.json")
      )
    stub_request(:get, "https://api-na.hosted.exlibrisgroup.com/almaws/v1/conf/libraries/marquand/locations")
      .with(
        headers: {
          'Accept' => 'application/json',
          'Authorization' => 'apikey TESTME'
        }
      )
      .to_return(
        status: 200,
        headers: { "content-Type" => "application/json" },
        body: file_fixture("alma/locations_marquand.json")
      )
    stub_request(:get, "https://api-na.hosted.exlibrisgroup.com/almaws/v1/conf/libraries/rare/locations")
      .with(
        headers: {
          'Accept' => 'application/json',
          'Authorization' => 'apikey TESTME'
        }
      )
      .to_return(
        status: 200,
        headers: { "content-Type" => "application/json" },
        body: file_fixture("alma/locations_rare.json")
      )
    stub_request(:get, "https://api-na.hosted.exlibrisgroup.com/almaws/v1/conf/libraries/mendel/locations")
      .with(
        headers: {
          'Accept' => 'application/json',
          'Authorization' => 'apikey TESTME'
        }
      )
      .to_return(
        status: 200,
        headers: { "content-Type" => "application/json" },
        body: file_fixture("alma/locations_mendel.json")
      )
    stub_request(:get, "https://api-na.hosted.exlibrisgroup.com/almaws/v1/conf/libraries/stokes/locations")
      .with(
        headers: {
          'Accept' => 'application/json',
          'Authorization' => 'apikey TESTME'
        }
      )
      .to_return(
        status: 200,
        headers: { "content-Type" => "application/json" },
        body: file_fixture("alma/locations_stokes.json")
      )
  end

  describe "#delete_existing_and_repopulate" do
    before do
      # Setup fake records to test if existing records are deleted
      test_library = Library.create(code: 'test', label: 'test')
      HoldingLocation.new(code: 'test', label: 'test') do |test_location|
        test_location.library = test_library
        test_location.save
      end
      DeliveryLocation.new(label: 'test', address: 'test') do |test_delivery_location|
        test_delivery_location.library = test_library
        test_delivery_location.save
      end
    end
    let(:firestone_library) { Library.find_by(code: 'firestone') }
    let(:scsb_delivery_location) do
      DeliveryLocation.create("label": "Firestone Circulation Desk",
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
      library_record = Library.find_by(code: 'arch')
      location_record1 = HoldingLocation.find_by(code: 'arch$stacks')
      location_record2 = HoldingLocation.find_by(code: 'annex$stacks')
      location_record3 = HoldingLocation.find_by(code: 'online$elf1')
      location_record4 = HoldingLocation.find_by(code: 'online$elf2')
      location_record5 = HoldingLocation.find_by(code: 'online$elf3')
      location_record6 = HoldingLocation.find_by(code: 'online$elf4')
      location_record7 = HoldingLocation.find_by(code: 'online$cdl')
      location_record8 = HoldingLocation.find_by(code: 'recap$gp')
      location_record9 = HoldingLocation.find_by(code: 'recap$pb')
      location_record10 = HoldingLocation.find_by(code: 'eastasian$hy')
      location_record11 = HoldingLocation.find_by(code: 'firestone$secw')
      location_record14 = HoldingLocation.find_by(code: 'stokes$spia')
      location_record15 = HoldingLocation.find_by(code: 'stokes$spr')

      expect(Library.count).to eq 12
      expect(HoldingLocation.count).to eq 119
      expect(library_record.label).to eq 'Architecture Library'
      expect(location_record2.label).to eq 'Stacks'
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
      expect(location_record11.label).to eq 'Scribner Library: Common Works Collection'
      expect(location_record14.label).to eq 'Wallace Hall (SPIA)'
      expect(location_record15.label).to eq 'Wallace Hall (SPR)'
    end

    it "Locations with fulfillment_unit: Reserves are not requestable" do
      LocationDataService.delete_existing_and_repopulate
      location_record12 = HoldingLocation.find_by(code: 'arch$res3hr')
      location_record13 = HoldingLocation.find_by(code: 'eastasian$reserve')

      expect(location_record12.fulfillment_unit).to eq 'Reserves'
      expect(location_record12.requestable).to eq false
      expect(location_record13.fulfillment_unit).to eq 'Reserves'
      expect(location_record13.requestable).to eq false
    end

    it "creates scsb locations" do
      LocationDataService.delete_existing_and_repopulate
      scsbnypl_record = HoldingLocation.find_by(code: 'scsbnypl')
      scsbhl_record = HoldingLocation.find_by(code: 'scsbhl')
      scsbcul_record = HoldingLocation.find_by(code: 'scsbcul')
      delivery_location_scsbcul = DeliveryLocation.all.find(scsbcul_record.delivery_location_ids.first)
      delivery_location_scsbhl = DeliveryLocation.all.find(scsbhl_record.delivery_location_ids.first)
      delivery_location_scsbnypl = DeliveryLocation.all.find(scsbnypl_record.delivery_location_ids.first)

      expect(delivery_location_record(scsbnypl_record).label).to eq 'Firestone Circulation Desk'
      expect(delivery_location_record(scsbnypl_record).gfa_pickup).to eq 'QX'
      expect(delivery_location_record(scsbhl_record).label).to eq 'Firestone Circulation Desk'
      expect(delivery_location_record(scsbcul_record).label).to eq 'Firestone Circulation Desk'
      expect(scsbcul_record.recap_electronic_delivery_location).to be true
      expect(scsbcul_record.remote_storage).to eq 'recap_rmt'
      expect(scsbhl_record.remote_storage).to eq 'recap_rmt'
      expect(scsbnypl_record.remote_storage).to eq 'recap_rmt'
      expect(scsbcul_record.label).to eq 'Remote Storage'
      expect(scsbcul_record.label).to eq 'Remote Storage'
      expect(scsbhl_record.label).to eq 'Remote Storage'
    end

    it "deletes existing delivery locations table and populates new from json file" do
      LocationDataService.delete_existing_and_repopulate
      library_record = Library.find_by(code: 'annex')
    end

    it "sets a static ID" do
      LocationDataService.delete_existing_and_repopulate
      # Run a second time to ensure idempotency.
      LocationDataService.delete_existing_and_repopulate

      location = DeliveryLocation.find_by(gfa_pickup: "PW")

      expect(location.id).to eq 3
      expect(location.label).to eq "Architecture Library"
      new_location = FactoryBot.create(:delivery_location)
      expect(new_location.id).to eq 31
    end

    describe "new recap locations" do
      before do
        LocationDataService.delete_existing_and_repopulate
      end
      it "they have recap_edd true and holding_library same as library" do
        location_engineer_pt = HoldingLocation.find_by(code: 'engineer$pt')
        location_arch_pw = HoldingLocation.find_by(code: 'arch$pw')
        location_firestone_pb = HoldingLocation.find_by(code: 'firestone$pb')
        location_lewis_pn = HoldingLocation.find_by(code: 'lewis$pn')
        location_marquand_pj = HoldingLocation.find_by(code: 'marquand$pj')
        location_mendel_pk = HoldingLocation.find_by(code: 'mendel$pk')
        location_rare_xw = HoldingLocation.find_by(code: 'rare$xw')
        expect(location_engineer_pt.recap_electronic_delivery_location).to be true
        expect(location_arch_pw.recap_electronic_delivery_location).to be true
        expect(location_firestone_pb.recap_electronic_delivery_location).to be true
        expect(location_lewis_pn.recap_electronic_delivery_location).to be true
        expect(location_marquand_pj.recap_electronic_delivery_location).to be true
        expect(location_mendel_pk.recap_electronic_delivery_location).to be true
        expect(location_engineer_pt.holding_library.label).to eq location_engineer_pt.library.label
        expect(location_arch_pw.holding_library.label).to eq location_arch_pw.library.label
        expect(location_firestone_pb.holding_library.label).to eq location_firestone_pb.library.label
        expect(location_lewis_pn.holding_library.label).to eq location_lewis_pn.library.label
        expect(location_marquand_pj.holding_library.label).to eq location_marquand_pj.library.label
        expect(location_rare_xw.holding_library.label).to eq location_rare_xw.library.label
        expect(location_mendel_pk.holding_library.label).to eq location_mendel_pk.library.label
      end
      it "new recap location rare$xw has recap_edd false" do
        location_rare_xw = HoldingLocation.find_by(code: 'rare$xw')
        expect(location_rare_xw.recap_electronic_delivery_location).to be false
      end
    end
  end

  def delivery_location_record(value)
    DeliveryLocation.all.find(value.delivery_location_ids.first)
  end
end
