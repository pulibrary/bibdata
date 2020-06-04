require 'rails_helper'
require 'json'

RSpec.describe AvailabilityController, type: :controller do
  describe '#index' do
    context 'when a single bib. ID is specified in the request' do
      before do
        get :index, params: { id: id }
      end

      context 'when the record cannot be found' do
        let(:id) { 'invalid' }

        it 'returns a 404 response' do
          expect(response.status).to eq(404)
          expect(response.body).to eq("Record: #{id} not found.")
        end
      end
    end
    context 'when a single MFHD ID is specified in the request' do
      before do
        get :index, params: { mfhd: mfhd }
      end

      context 'when the record cannot be found' do
        let(:mfhd) { 'invalid' }

        it 'returns a 404 response' do
          expect(response.status).to eq(404)
          expect(response.body).to eq("Record: #{mfhd} not found.")
        end
      end
    end
  end

  describe 'bib availability hash' do
    it 'provides availability for only the first 2 holdings by default' do
      allow(VoyagerHelpers::Liberator).to receive(:get_availability).and_return("929437"=>{ "1068356"=>{ more_items: false, location: "rcppa", status: ["Not Charged"] }, "1068357"=>{ more_items: false, location: "fnc", status: ["Not Charged"] } })
      bib_3_holdings = '929437'
      get :index, params: { ids: [bib_3_holdings], format: :json }
      availability = JSON.parse(response.body)
      bib_availability = availability[bib_3_holdings]
      holding_locations = bib_availability.each_value.map { |holding| holding['location'] }
      expect(holding_locations).to include('rcppa')
      expect(holding_locations).to include('fnc')
      expect(holding_locations).not_to include('anxb')
    end

    it 'provides availability for all holdings if full availability requested' do
      allow(VoyagerHelpers::Liberator).to receive(:get_availability).and_return("1068356"=>{ more_items: false, location: "rcppa", status: ["Not Charged"] }, "1068357"=>{ more_items: false, location: "fnc", status: ["Not Charged"] }, "1068358"=>{ more_items: false, location: "anxb", status: ["Not Charged"] })
      bib_3_holdings = '929437'
      get :index, params: { id: bib_3_holdings, format: :json }
      availability = JSON.parse(response.body)
      holding_locations = availability.each_value.map { |holding| holding['location'] }
      expect(holding_locations).to include('rcppa')
      expect(holding_locations).to include('fnc')
      expect(holding_locations).to include('anxb')
    end
  end

  describe 'holding availability hash' do
    let(:lib_loc) { Locations::Library.new(label: 'Library') }
    let(:holding_loc_non_circ) { Locations::HoldingLocation.new(circulates: false, always_requestable: false, library: lib_loc, label: '') }
    let(:holding_loc_always_req) { Locations::HoldingLocation.new(circulates: false, always_requestable: true, library: lib_loc, label: '') }
    let(:holding_loc_label) { Locations::HoldingLocation.new(circulates: false, label: 'Special Room', library: lib_loc) }
    it 'voyager status is returned for item' do
      allow(VoyagerHelpers::Liberator).to receive(:get_availability).and_return("35345"=>{ "39176"=>{ more_items: false, location: "f", status: ["Not Charged"] } })
      bib_with_item = '35345'
      holding_id = '39176'
      item_id = 36736
      get :index, params: { ids: [bib_with_item], format: :json }
      availability = JSON.parse(response.body)
      expect(availability[bib_with_item][holding_id]['status']).to eq('Not Charged')
    end

    context 'when a connection error is encountered for Voyager' do
      let(:bib_with_item) { '35345' }

      before do
        allow(Rails.logger).to receive(:error)

        # See https://github.com/pulibrary/marc_liberation/issues/292
        class OCIError < StandardError; end if ENV['CI']

        allow(VoyagerHelpers::Liberator).to receive(:get_availability).and_raise(OCIError)
      end

      after do
        # See https://github.com/pulibrary/marc_liberation/issues/292
        Object.send(:remove_const, :OCIError) if ENV['CI']
      end

      it 'logs an error and returns a 404 status response' do
        get :index, params: { ids: [bib_with_item], format: :json }
        expect(response.status).to eq(404)
        expect(Rails.logger).to have_received(:error).with("Error encountered when requesting availability status: OCIError")
      end
    end

    it 'elf records have a status of online' do
      allow(VoyagerHelpers::Liberator).to receive(:get_availability).and_return("7916044"=>{ "7698138"=>{ more_items: false, location: "elf1", status: "Online" }, "7860428"=>{ more_items: false, location: "rcpph", status: ["Not Charged"] } })
      bib_online = '7916044'
      holding_id = '7698138'
      get :index, params: { ids: [bib_online], format: :json }
      availability = JSON.parse(response.body)
      expect(availability[bib_online][holding_id]['location']).to eq('elf1')
      expect(availability[bib_online][holding_id]['status']).to eq('Online')
    end

    it 'on-order records have a status of On-Order' do
      allow(VoyagerHelpers::Liberator).to receive(:get_availability).and_return("9173362"=>{ "9051785"=>{ more_items: false, location: "f", status: "On-Order 09-10-2015" } })
      bib_on_order = '9173362'
      holding_id = '9051785'
      get :index, params: { ids: [bib_on_order], format: :json }
      availability = JSON.parse(response.body)
      expect(availability[bib_on_order][holding_id]['status']).to include('On-Order')
    end

    it 'limited access location on-order records have a status of On-Order' do
      allow(VoyagerHelpers::Liberator).to receive(:get_availability).and_return("9355531"=>{ more_items: false, location: "sa", status: "On-Order" })
      marquand = '9497429'
      get :index, params: { id: marquand, format: :json }
      availability = JSON.parse(response.body)
      key, value = availability.first
      expect(value['location']).to eq('sa')
      expect(value['status']).to include('On-Order')
    end

    it 'items without a temp_loc have a location display label' do
      allow(VoyagerHelpers::Liberator).to receive(:get_availability).and_return("9355531"=>{ more_items: false, location: "sa", status: "On-Order" })
      allow_any_instance_of(described_class).to receive(:get_holding_location).and_return(holding_loc_always_req)
      marquand = '9497429'
      get :index, params: { id: marquand, format: :json }
      availability = JSON.parse(response.body)
      key, value = availability.first
      expect(value['temp_loc']).to be nil
      expect(value['label']).to eq 'Library'
    end

    it 'online on-order records have a status of On-Order' do
      allow(VoyagerHelpers::Liberator).to receive(:get_availability).and_return("9096471"=>{ more_items: false, location: "elf1", status: "On-Order" })
      online = '9226664'
      get :index, params: { id: online, format: :json }
      availability = JSON.parse(response.body)
      key, value = availability.first
      expect(value['location']).to include('elf')
      expect(value['status']).to include('On-Order')
    end

    it 'Received on-order records have a status of Order Received' do
      allow(VoyagerHelpers::Liberator).to receive(:get_availability).and_return("9329199"=>{ more_items: false, location: "f", status: "Order Received 12-16-2015" })
      bib_received_order = '9468468'
      get :index, params: { id: bib_received_order, format: :json }
      availability = JSON.parse(response.body)
      expect(availability.first[1]['status']).to include('Order Received')
    end

    describe 'location-based availability' do
      it 'always_requestable locations should display order information status' do
        allow_any_instance_of(described_class).to receive(:get_holding_location).and_return(holding_loc_always_req)
        allow(VoyagerHelpers::Liberator).to receive(:get_availability).and_return("4609321"=>{ "4847980"=>{ more_items: false, location: "whs", status: "Order Received 12-16-2015" } })
        bible = '4609321'
        holding_id = '4847980'
        get :index, params: { ids: [bible], format: :json }
        availability = JSON.parse(response.body)
        expect(availability[bible][holding_id]['status']).to include('Order Received')
      end
      it 'non_circulating, always_requestable locations have a status of on-site when available' do
        allow_any_instance_of(described_class).to receive(:get_holding_location).and_return(holding_loc_always_req)
        allow(VoyagerHelpers::Liberator).to receive(:get_availability).and_return("4609321"=>{ "4847980"=>{ more_items: false, location: "whs", status: "On Shelf" } })
        bible = '4609321'
        holding_id = '4847980'
        get :index, params: { ids: [bible], format: :json }
        availability = JSON.parse(response.body)
        expect(availability[bible][holding_id]['status']).to eq(controller.send(:on_site))
      end
      it 'non_circulating, always_requestable locations include status when unavailable' do
        allow_any_instance_of(described_class).to receive(:get_holding_location).and_return(holding_loc_always_req)
        allow(VoyagerHelpers::Liberator).to receive(:get_availability).and_return("4609321"=>{ "4847980"=>{ more_items: false, location: "whs", status: "Unavailable" } })
        bible = '4609321'
        holding_id = '4847980'
        get :index, params: { ids: [bible], format: :json }
        availability = JSON.parse(response.body)
        expect(availability[bible][holding_id]['status']).to include(controller.send(:on_site), 'Unavailable')
      end
      it 'non_circulating, non always_requestable locations have a status of on-site when available' do
        allow_any_instance_of(described_class).to receive(:get_holding_location).and_return(holding_loc_non_circ)
        allow(VoyagerHelpers::Liberator).to receive(:get_availability).and_return("4609321"=>{ "4847980"=>{ more_items: false, location: "whs", status: "On Shelf" } })
        bible = '4609321'
        holding_id = '4847980'
        get :index, params: { ids: [bible], format: :json }
        availability = JSON.parse(response.body)
        expect(availability[bible][holding_id]['status']).to eq(controller.send(:on_site))
      end
      it 'non_circulating, non always_requestable locations display non-available statuses' do
        allow_any_instance_of(described_class).to receive(:get_holding_location).and_return(holding_loc_non_circ)
        allow(VoyagerHelpers::Liberator).to receive(:get_availability).and_return("4609321"=>{ "4847980"=>{ more_items: false, location: "whs", status: "Unavailable" } })
        bible = '4609321'
        holding_id = '4847980'
        get :index, params: { ids: [bible], format: :json }
        availability = JSON.parse(response.body)
        expect(availability[bible][holding_id]['status']).to eq('Unavailable')
      end
    end

    it 'Items with temp location codes are have a temp_loc key' do
      allow_any_instance_of(described_class).to receive(:get_holding_location).and_return(holding_loc_label)
      temp_loc = 'woooo'
      allow(VoyagerHelpers::Liberator).to receive(:get_availability).and_return("9329199"=>{ more_items: false, location: "f", temp_loc: temp_loc, status: ["Charged"] })
      bib_received_order = '9468468'
      get :index, params: { id: bib_received_order, format: :json }
      availability = JSON.parse(response.body)
      expect(availability.first[1]['temp_loc']).to eq(temp_loc)
    end

    it 'Items with temp location codes are mapped the display value' do
      allow_any_instance_of(described_class).to receive(:get_holding_location).and_return(holding_loc_label)
      allow(VoyagerHelpers::Liberator).to receive(:get_availability).and_return("9329199"=>{ more_items: false, location: "f", temp_loc: 'woooo', status: ["Charged"] })
      bib_received_order = '9468468'
      get :index, params: { id: bib_received_order, format: :json }
      availability = JSON.parse(response.body)
      expect(availability.first[1]['label']).to include(holding_loc_label.label, holding_loc_label.library.label)
    end

    it 'temp location codes with no holding loc label display on library name' do
      allow_any_instance_of(described_class).to receive(:get_holding_location).and_return(holding_loc_non_circ)
      allow(VoyagerHelpers::Liberator).to receive(:get_availability).and_return("9329199"=>{ more_items: false, location: "f", temp_loc: 'woooo', status: ["Charged"] })
      bib_received_order = '9468468'
      get :index, params: { id: bib_received_order, format: :json }
      availability = JSON.parse(response.body)
      expect(availability.first[1]['label']).to eq(holding_loc_non_circ.library.label)
    end

    it 'all other holding records without items have a status of On Shelf' do
      allow(VoyagerHelpers::Liberator).to receive(:get_availability).and_return("7617477"=>{ "7429805"=>{ more_items: false, location: "f", status: "On Shelf" }, "7429809"=>{ more_items: false, location: "sci", status: "On Shelf" } })
      bib_ipad = '7617477'
      holding_id = '7429805'
      get :index, params: { ids: [bib_ipad], format: :json }
      availability = JSON.parse(response.body)
      expect(availability[bib_ipad][holding_id]['status']).to eq('On Shelf')
    end

    it 'more_items is true when there is more than 1 item for a holding' do
      allow(VoyagerHelpers::Liberator).to receive(:get_availability).and_return("857469"=>{ "977093"=>{ more_items: true, location: "f", status: ["Not Charged"] }, "977094"=>{ more_items: true, location: "rcppf", status: ["Not Charged"] } })
      bib_multiple_items = '857469'
      holding_id = '977093'
      get :index, params: { ids: [bib_multiple_items], format: :json }
      availability = JSON.parse(response.body)
      expect(availability[bib_multiple_items][holding_id]['more_items']).to eq(true)
    end

    it 'more_items is false when there is 1 item or less for a holding' do
      allow(VoyagerHelpers::Liberator).to receive(:get_availability).and_return("35345"=>{ "39176"=>{ more_items: false, location: "f", status: ["Not Charged"] } })
      bib_1_item = '35345'
      holding_id = '39176'
      get :index, params: { ids: [bib_1_item], format: :json }
      availability = JSON.parse(response.body)
      expect(availability[bib_1_item][holding_id]['more_items']).to eq(false)
    end
  end

  describe 'availability for item with multiple statuses' do
    it 'returns status with highest priority' do
      bib_id = '7135944'
      holding_id = '7002641'
      allow(VoyagerHelpers::Liberator).to receive(:get_availability).and_return(7135944=>{ "7002641"=>{ more_items: false, location: "mus", copy_number: 1, item_id: 6406359, on_reserve: "N", status: ["Overdue", "Lost--System Applied", "In Process"] } } )
      get :index, params: { ids: [bib_id], format: :json }
      availability = JSON.parse(response.body)
      expect(availability[bib_id][holding_id]['status']).to eq('Lost--System Applied')
    end
  end

  describe 'availability for items with hold request status' do
    let(:lib_recap) { Locations::Library.new(code: 'recap') }
    let(:lib_other) { Locations::Library.new(code: 'other') }
    let(:holding_recap_non_aeon) { Locations::HoldingLocation.new(aeon_location: false, library: lib_recap, label: '') }
    let(:holding_recap_aeon) { Locations::HoldingLocation.new(aeon_location: true, always_requestable: true, library: lib_recap, label: '') }
    let(:holding_non_recap) { Locations::HoldingLocation.new(library: lib_other, label: '') }
    let(:bib_id) { '35345' }
    let(:holding_id) { '39176' }
    let(:hold_request) { controller.send(:hold_request) }
    let(:recap_non_aeon) do
      { bib_id => { holding_id => { more_items: false, location: "rcppn", status: hold_request } } }
    end
    it 'recap non-aeon item returns status of hold request' do
      allow_any_instance_of(described_class).to receive(:get_holding_location).and_return(holding_recap_non_aeon)
      allow(VoyagerHelpers::Liberator).to receive(:get_availability).and_return(recap_non_aeon)
      get :index, params: { ids: [bib_id], format: :json }
      availability = JSON.parse(response.body)
      expect(availability[bib_id][holding_id]['status']).to eq(hold_request)
    end
    it 'recap aeon, always requestable, items returns on site status' do
      allow_any_instance_of(described_class).to receive(:get_holding_location).and_return(holding_recap_aeon)
      allow(VoyagerHelpers::Liberator).to receive(:get_availability).and_return(recap_non_aeon)
      get :index, params: { ids: [bib_id], format: :json }
      availability = JSON.parse(response.body)
      expect(availability[bib_id][holding_id]['status']).to eq(controller.send(:on_site))
    end
    it 'non recap item returns status of not charged' do
      allow_any_instance_of(described_class).to receive(:get_holding_location).and_return(holding_non_recap)
      allow(VoyagerHelpers::Liberator).to receive(:get_availability).and_return(recap_non_aeon)
      get :index, params: { ids: [bib_id], format: :json }
      availability = JSON.parse(response.body)
      expect(availability[bib_id][holding_id]['status']).to eq(controller.send(:not_charged))
    end
  end

  describe 'full mfhd availability array' do
    it 'returns info for all items for a given mfhd' do
      allow(VoyagerHelpers::Liberator).to receive(:get_full_mfhd_availability).and_return([
       { barcode:"32101033513878", id:282630, location:"f", copy_number:1, item_sequence_number:12, status:["Not Charged"], on_reserve:"N", item_type:"NoCirc", pickup_location_id:299, pickup_location_code:"fcirc", enum:"vol.20(inc.)", chron:"1994", enum_display:"vol.20(inc.) (1994)", label:"Firestone Library" },
       { barcode:"32101024070318", id:282629, location:"f", copy_number:1, item_sequence_number:11, status:["Not Charged"], on_reserve:"N", item_type:"Gen", pickup_location_id:299, pickup_location_code:"fcirc", enum:"vol.19", chron:"1993", enum_display:"vol.19 (1993)", label:"Firestone Library" },
       { barcode:"32101086430665", id:6786508, location:"f", copy_number:1, item_sequence_number:26, status:["Not Charged"], on_reserve:"N", item_type:"Gen", pickup_location_id:299, pickup_location_code:"fcirc", enum:"vol. 38", chron:"2012", enum_display:"vol. 38 (2012)", label:"Firestone Library" } 
      ])
      holding_id = '282033'
      get :index, params: { mfhd: holding_id, format: :json }
      availability = JSON.parse(response.body)
      item_282630 = availability[0]
      item_282629 = availability[1]
      expect(item_282630["item_type"]).to eq "NoCirc"
      expect(item_282630["pickup_location_id"]).to eq 299
      expect(item_282630["pickup_location_code"]).to eq "fcirc"
      expect(item_282629["item_type"]).to eq "Gen"
      expect(availability.length).to eq(3)
    end


  end

  describe 'mfhd_serial location has current' do
    it '404 when no volumes found for given mfhd' do
      allow(VoyagerHelpers::Liberator).to receive(:get_current_issues).and_return([])
      get :index, params: { mfhd_serial: '12345678901', format: :json }
      expect(response).to have_http_status(404)
    end
    it 'current volumes for given_mfhd are parsed as an array' do
      allow(VoyagerHelpers::Liberator).to receive(:get_current_issues).and_return(['v1', 'v2', 'v3'])
      get :index, params: { mfhd_serial: '12345678901', format: :json }
      current_issues = JSON.parse(response.body)
      expect(current_issues).to match_array(['v1', 'v2', 'v3'])
    end
  end

  describe 'scsb bib id' do

    let(:scsb_good_lookup) { ScsbLookup.new }
    let(:scsb_bad_lookup) { ScsbLookup.new }
    let(:scsb_id) { '5270946' }
    let(:no_id) { 'foo' }
    let(:bib_response) do
      {
        '32101055068314':
        {
          "itemBarcode": "32101055068314",
          "itemAvailabilityStatus": "Available",
          "errorMessage": nil
        }
      }.with_indifferent_access
    end
    it '404 when no item ID exists' do
      stub_request(:post, "https://test.api.com/sharedCollection/bibAvailabilityStatus").
         with(body: "{\"bibliographicId\":\"foo\",\"institutionId\":\"scsb\"}",
              headers: { 'Accept'=>'application/json', 'Accept-Encoding'=>'gzip;q=1.0,deflate;q=0.6,identity;q=0.3', 'Api-Key'=>'TESTME', 'Content-Type'=>'application/json' }).
         to_return(status: 404, body: "", headers: {})
      allow(scsb_good_lookup).to receive(:find_by_id).and_return({})
      get :index, params: { scsb_id: no_id, format: :json }
      expect(response).to have_http_status(404)
    end

    it 'returns barcodes and status attached to the id' do
      stub_request(:post, "https://test.api.com/sharedCollection/bibAvailabilityStatus").
         with(body: '{"bibliographicId":"5270946","institutionId":"scsb"}',
              headers: { 'Accept'=>'application/json', 'Accept-Encoding'=>'gzip;q=1.0,deflate;q=0.6,identity;q=0.3', 'Api-Key'=>'TESTME', 'Content-Type'=>'application/json' }).
         to_return(status: 200, body: '[{ "itemBarcode": "32101055068314", "itemAvailabilityStatus": "Available", "errorMessage": null}]', headers: {})
      allow(scsb_good_lookup).to receive(:find_by_id).and_return([
        {
          "itemBarcode": "32101055068314",
          "itemAvailabilityStatus": "Available",
          "errorMessage": nil
        }
      ])
      get :index, params: { scsb_id: scsb_id, format: :json }
      bib_barcodes = JSON.parse(response.body)
      expect(bib_barcodes).to eq(bib_response)
    end
  end

  describe 'scsb by barcode' do

    let(:scsb_good_lookup) { ScsbLookup.new }
    let(:scsb_bad_lookup) { ScsbLookup.new }
    let(:scsb_id) { '5270946' }
    let(:no_id) { 'foo' }
    let(:bib_response) do
      {
        '32101055068314':
        {
          "itemBarcode": "32101055068314",
          "itemAvailabilityStatus": "Available",
          "errorMessage": nil
        },
        '32101055068313':
        {
          "itemBarcode": "32101055068313",
          "itemAvailabilityStatus": "Available",
          "errorMessage": nil
        }
      }.with_indifferent_access
    end
    it '404 when no item ID exists' do
      stub_request(:post, "https://test.api.com/sharedCollection/itemAvailabilityStatus").
         with(body: "{\"barcodes\":[\"foo\",\"blah\"]}",
              headers: { 'Accept'=>'application/json', 'Accept-Encoding'=>'gzip;q=1.0,deflate;q=0.6,identity;q=0.3', 'Api-Key'=>'TESTME', 'Content-Type'=>'application/json' }).
         to_return(status: 404, body: "", headers: {})
      allow(scsb_good_lookup).to receive(:find_by_barcodes).and_return({})
      get :index, params: { barcodes: ['foo', 'blah'], format: :json }
      expect(response).to have_http_status(404)
    end

    it 'returns barcodes and status attached to the id' do
      stub_request(:post, "https://test.api.com/sharedCollection/itemAvailabilityStatus").
         with(body: "{\"barcodes\":[\"32101055068314\",\"32101055068313\"]}",
              headers: { 'Accept'=>'application/json', 'Accept-Encoding'=>'gzip;q=1.0,deflate;q=0.6,identity;q=0.3', 'Api-Key'=>'TESTME', 'Content-Type'=>'application/json' }).
         to_return(status: 200, body: '[{ "itemBarcode": "32101055068314", "itemAvailabilityStatus": "Available", "errorMessage": null},{ "itemBarcode": "32101055068313", "itemAvailabilityStatus": "Available", "errorMessage": null}]', headers: {})
      allow(scsb_bad_lookup).to receive(:find_by_barcodes).and_return([
        {
          "itemBarcode": "32101055068314",
          "itemAvailabilityStatus": "Available",
          "errorMessage": nil
        },
        {
          "itemBarcode": "32101055068313",
          "itemAvailabilityStatus": "Available",
          "errorMessage": nil
        }
      ])
      get :index, params: { barcodes: ['32101055068314', '32101055068313'], format: :json }
      bib_barcodes = JSON.parse(response.body)
      expect(bib_barcodes).to eq(bib_response)
    end
  end

  it "404 when bibs are not provided" do
    allow(VoyagerHelpers::Liberator).to receive(:get_availability).and_return({})
    get :index, params: { ids: [], format: :json }
    expect(response).to have_http_status(404)
  end

  it "404 when records are not found" do
    allow(VoyagerHelpers::Liberator).to receive(:get_availability).and_return({})
    get :index, params: { ids: ['12345678901'], format: :json }
    expect(response).to have_http_status(404)
  end

end
