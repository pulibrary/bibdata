require 'rails_helper'
require 'json'

RSpec.describe AvailabilityController, type: :controller do
  describe '#index with ids param' do
    it "responds with bib availability json" do
      bib_id = '929437'
      holding1 = "1068356"
      holding2 = "1068357"
      allow(VoyagerHelpers::Liberator).to receive(:get_availability).and_return(bib_id=>{ holding1=>{ more_items: false, location: "rcppa", status: ["Not Charged"] }, holding2=>{ more_items: false, location: "fnc", patron_group_charged: nil, status: ["Not Charged"] } })
      get :index, params: { ids: [bib_id], format: :json }
      availability = JSON.parse(response.body)
      expect(availability.keys).to eq [bib_id]
      bib_availability = availability[bib_id]
      expect(bib_availability.keys).to eq [holding1, holding2]
      expect(bib_availability.values.flat_map { |h| h['location'] }).to eq ['rcppa', 'fnc']
    end

    context "when records are not found" do
      it "404s" do
        allow(VoyagerLookup).to receive(:multiple_bib_availability).and_return({})
        get :index, params: { ids: ['12345678901'], format: :json }
        expect(response).to have_http_status(404)
      end
    end
  end

  describe '#index with id param' do
    it 'responds with holdings availability json' do
      holding1 = "1068356"
      holding2 = "1068357"
      holding3 = "1068358"
      allow(VoyagerHelpers::Liberator).to receive(:get_availability).and_return("1068356"=>{ more_items: false, location: "rcppa", status: ["Not Charged"] }, "1068357"=>{ more_items: false, location: "fnc", status: ["Not Charged"] }, "1068358"=>{ more_items: false, location: "anxb", patron_group_charged: nil, status: ["Not Charged"] })
      bib_id = '929437'
      get :index, params: { id: bib_id, format: :json }
      availability = JSON.parse(response.body)
      expect(availability.keys).to eq [holding1, holding2, holding3]
      holding_locations = availability.values.flat_map { |h| h['location'] }
      expect(holding_locations).to eq ['rcppa', 'fnc', 'anxb']
    end

    context 'when the record cannot be found' do
      let(:id) { 'invalid' }

      it 'returns a 404 response' do
        get :index, params: { id: id }
        expect(response.status).to eq(404)
        expect(response.body).to eq("Record: #{id} not found.")
      end
    end
  end

  describe '#index with mfhd param' do
    it 'returns info for all items for a given mfhd' do
      allow(VoyagerHelpers::Liberator).to receive(:get_full_mfhd_availability).and_return([
       { barcode:"32101033513878", id:282630, location:"f", copy_number:1, item_sequence_number:12, status:["Not Charged"], on_reserve:"N", item_type:"NoCirc", pickup_location_id:299, patron_group_charged: nil, pickup_location_code:"fcirc", enum:"vol.20(inc.)", chron:"1994", enum_display:"vol.20(inc.) (1994)", label:"Firestone Library" },
       { barcode:"32101024070318", id:282629, location:"f", copy_number:1, item_sequence_number:11, status:["Not Charged"], on_reserve:"N", item_type:"Gen", pickup_location_id:299, patron_group_charged: nil, pickup_location_code:"fcirc", enum:"vol.19", chron:"1993", enum_display:"vol.19 (1993)", label:"Firestone Library" },
       { barcode:"32101086430665", id:6786508, location:"f", copy_number:1, item_sequence_number:26, status:["Not Charged"], on_reserve:"N", item_type:"Gen", pickup_location_id:299, patron_group_charged: nil, pickup_location_code:"fcirc", enum:"vol. 38", chron:"2012", enum_display:"vol. 38 (2012)", label:"Firestone Library" } 
      ])
      holding_id = '282033'
      get :index, params: { mfhd: holding_id, format: :json }
      availability = JSON.parse(response.body)
      expect(availability.count).to eq 3
      item1 = availability[0]
      item2 = availability[1]
      expect(item1["item_type"]).to eq "NoCirc"
      expect(item1["pickup_location_id"]).to eq 299
      expect(item1["pickup_location_code"]).to eq "fcirc"
      expect(item2["item_type"]).to eq "Gen"
    end

    context 'when the record cannot be found' do
      let(:mfhd) { 'invalid' }

      it 'returns a 404 response' do
        get :index, params: { mfhd: mfhd }
        expect(response.status).to eq(404)
        expect(response.body).to eq("Record: #{mfhd} not found.")
      end
    end
  end

  describe '#index with mfhd_serial param' do
    it 'parses current volumes for given_mfhd as an array' do
      allow(VoyagerHelpers::Liberator).to receive(:get_current_issues).and_return(['v1', 'v2', 'v3'])
      get :index, params: { mfhd_serial: '12345678901', format: :json }
      current_issues = JSON.parse(response.body)
      expect(current_issues).to match_array(['v1', 'v2', 'v3'])
    end

    context "when no volumes are found" do
      it 'responds with a 404' do
        allow(VoyagerHelpers::Liberator).to receive(:get_current_issues).and_return([])
        get :index, params: { mfhd_serial: '12345678901', format: :json }
        expect(response).to have_http_status(404)
      end
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
end
