require 'rails_helper'

RSpec.describe BibliographicController, type: :controller do
  render_views
  let(:unsuppressed) { "991227850000541" }
  let(:ark_record) { "99226236706421" }
  let(:ark_record_xml) { file_fixture("alma/ark_#{ark_record}.xml").read }
  let(:marc_99226236706421) { MARC::XMLReader.new(StringIO.new(ark_record_xml)).first }
  let(:unsuppressed_xml) { file_fixture("alma/unsuppressed_#{unsuppressed}.xml").read }
  let(:marc_991227850000541) { MARC::XMLReader.new(StringIO.new(unsuppressed_xml)).first }
  let(:bib_id) { '1234567' }
  let(:bib_record) { instance_double(MARC::Record) }
  let(:file_path) { Rails.root.join('spec', 'fixtures', "#{bib_id}.mrx") }
  let(:bib_record_xml) { File.read(file_path) }
  let(:one_bib) { "991227850000541" }
  let(:adapter) { AlmaAdapter.new }

  before do
    # allow(bib_record).to receive(:to_xml).and_return bib_record_xml
    # allow(VoyagerHelpers::Liberator).to receive(:get_bib_record).and_return bib_record
    allow(AlmaAdapter).to receive(:new).and_return(adapter)
  end

  describe '#bib' do
    let(:unsuppressed) { "99121886293506421" }
    before do
      stub_alma_ids(ids: "99121886293506421", status: 200)
    end
    it 'renders a marc xml record' do
      get :bib, params: { bib_id: unsuppressed }, format: :xml
      expect(response.body).not_to be_empty
      expect(response.body).to include("record xmlns='http://www.loc.gov/MARC21/slim'")
      record = MARC::XMLReader.new(StringIO.new(response.body)).first
      expect(record["AVA"]).to be_present
    end

    it "doesn't render AVA/AVE if holdings=false" do
      get :bib, params: { bib_id: unsuppressed, holdings: false }, format: :xml
      expect(response.body).not_to be_empty
      expect(response.body).to include("record xmlns='http://www.loc.gov/MARC21/slim'")
      record = MARC::XMLReader.new(StringIO.new(response.body)).first
      expect(record["AVA"]).not_to be_present
    end

    context 'when an error is encountered in the controller' do
      before do
        allow(Rails.logger).to receive(:error)
        allow(adapter).to receive(:get_bib_record).and_raise("it's broken")
      end
      it 'returns HTTP 500 (internal error) response and logs an error' do
        get :bib, params: { bib_id: }
        expect(response.status).to eq 500
        expect(Rails.logger).to have_received(:error).with("HTTP 500. Failed to retrieve the record using the bib. ID: 1234567 it's broken")
      end
    end

    context 'when an API error is encountered while querying Alma' do
      before do
        allow(Rails.logger).to receive(:error)
        allow(adapter).to receive(:get_bib_record).and_raise(Alma::StandardError, "it's broken")
      end
      it 'returns HTTP 400 (bad request) response and logs an error' do
        get :bib, params: { bib_id: }
        expect(response.status).to eq 400
        expect(Rails.logger).to have_received(:error).with("HTTP 400. Failed to retrieve the record using the bib. ID: 1234567 it's broken")
      end
    end
  end

  describe '#bib_holdings' do
    # see https://github.com/pulibrary/marc_liberation/issues/1041
    # if we migrate the implementation to alma-rb we may not have this issue
    context 'when the endpoint comes back with ascii-8bit' do
      let(:ascii_8bit_response) { "994304723506421" }
      it 'converts to utf-8' do
        fixture = file_fixture("alma/#{ascii_8bit_response}.xml")
        stub_request(:get, "https://alma/almaws/v1/bibs/#{ascii_8bit_response}/holdings?apikey=TESTME")
          .to_return(status: 200, body: IO.binread(fixture))

        get :bib_holdings, params: { bib_id: ascii_8bit_response }, format: 'xml'

        expect(response.body.encoding.to_s).to eq "UTF-8"
      end
    end
  end

  describe '#bib_items' do
    context "A record with one location" do
      let(:bib_items_po) { "99227515106421" }
      let(:expected_response) do
        {
          "MAIN$main" => [
            { "holding_id" => "2284011070006421",
              "call_number" => "PN1993.I",
              "items" => [
                { "pid" => "2384011050006421",
                  "id" => "2384011050006421",
                  "cdl" => false,
                  "temp_location" => nil,
                  "perm_location" => "MAIN$main" }
              ] }
          ]
        }
      end

      it "has the exact required keys, values" do
        stub_alma_bib_items(mms_id: bib_items_po, filename: "#{bib_items_po}_po.json")
        get :bib_items, params: { bib_id: bib_items_po }, format: 'json'
        expect(response.status).to be 200
        locations = JSON.parse(response.body)
        expect(locations).to eq expected_response
      end
    end

    context "A record with two locations, two items in each location" do
      let(:unsuppressed_two_loc_two_items) { "99223608406421" }
      let(:fixture) { "#{unsuppressed_two_loc_two_items}_two_locations_two_items.json" }
      let(:expected_response) do
        {
          "MAIN$RESERVES" => [
            { "call_number" => "Q175 .N3885 1984", "holding_id" => "2282241690006421", "items" => [
              { "id" => "2382260850006421", "perm_location" => "MAIN$RESERVES", "pid" => "2382260850006421", "temp_location" => nil, "cdl" => false },
              { "id" => "2382241620006421", "perm_location" => "MAIN$RESERVES", "pid" => "2382241620006421", "temp_location" => nil, "cdl" => false }
            ] }
          ],
          "MAIN$offsite" => [
            { "call_number" => "Q175 .N3885 1984", "holding_id" => "2282241870006421", "items" => [
              { "id" => "2382260930006421", "perm_location" => "MAIN$offsite", "pid" => "2382260930006421", "temp_location" => nil, "cdl" => false },
              { "id" => "2382241780006421", "perm_location" => "MAIN$offsite", "pid" => "2382241780006421", "temp_location" => nil, "cdl" => false }
            ] }
          ]
        }
      end
      it "returns a hash with 2 locations" do
        stub_alma_bib_items(mms_id: unsuppressed_two_loc_two_items, filename: fixture)
        get :bib_items, params: { bib_id: unsuppressed_two_loc_two_items }, format: 'json'
        expect(response.status).to be 200
        locations = JSON.parse(response.body)
        expect(locations).to eq expected_response
      end
    end

    context "A record with two locations and two different holdings in one location" do
      let(:unsuppressed_loc_with_two_holdings) { "99229556706421" }
      let(:fixture) { "#{unsuppressed_loc_with_two_holdings}_two_loc_two_holdings_sort_library_asc.json" }
      let(:expected_response) do
        {
          "MAIN$main" => [{ "call_number" => "HG2491 .S65 1996", "holding_id" => "2284629920006421", "items" => [{ "id" => "2384629900006421", "perm_location" => "MAIN$main", "pid" => "2384629900006421", "temp_location" => nil, "cdl" => false }, { "id" => "2384621860006421", "perm_location" => "MAIN$main", "pid" => "2384621860006421", "temp_location" => nil, "cdl" => false }] }, { "call_number" => "HG2491 .S65 1996 c. 3", "holding_id" => "2284621880006421", "items" => [{ "id" => "2384621850006421", "perm_location" => "MAIN$main", "pid" => "2384621850006421", "temp_location" => nil, "cdl" => false }, { "id" => "2384621840006421", "perm_location" => "MAIN$main", "pid" => "2384621840006421", "temp_location" => nil, "cdl" => false }] }],
          "MUS$music" => [{ "call_number" => "HG2491 .S65 1996", "holding_id" => "2284621870006421", "items" => [{ "id" => "2384621830006421", "perm_location" => "MUS$music", "pid" => "2384621830006421", "temp_location" => nil, "cdl" => false }, { "id" => "2384621820006421", "perm_location" => "MUS$music", "pid" => "2384621820006421", "temp_location" => nil, "cdl" => false }] }]
        }
      end

      it "returns the locations, holdings, and items JSON" do
        stub_alma_bib_items(mms_id: unsuppressed_loc_with_two_holdings, filename: fixture)
        get :bib_items, params: { bib_id: unsuppressed_loc_with_two_holdings }, format: 'json'
        expect(response.status).to be 200
        locations = JSON.parse(response.body)
        expect(locations).to eq expected_response
      end
    end

    context "when a record has holdings with a temporary location" do
      let(:bib_items) { "9999362473506421" }
      let(:fixture) { "#{bib_items}_items.json" }

      it "returns holdings item with a temp location value" do
        stub_alma_bib_items(mms_id: bib_items, filename: fixture)
        get :bib_items, params: { bib_id: bib_items }, format: 'json'
        expect(response.status).to be 200
        locations = JSON.parse(response.body)
        expect(locations["lewis$resterm"][0]["items"][0]["temp_location"]).to eq "lewis$resterm"
      end
    end

    context "when a record has an item on CDL" do
      let(:bib_items) { "9965126093506421" }
      let(:fixture) { "cdl_#{bib_items}_bib_items.json" }

      it "returns holdings item with a temp location value" do
        stub_alma_bib_items(mms_id: bib_items, filename: fixture)
        get :bib_items, params: { bib_id: bib_items }, format: 'json'
        expect(response.status).to be 200
        body = JSON.parse(response.body)
        expect(body["firestone$stacks"].first["items"].first["cdl"]).to eq true
      end
    end

    context "sortable call number " do
      it "handles normal call numbers" do
        stub_alma_bib_items(mms_id: "9965126093506421", filename: "cdl_9965126093506421_bib_items.json")
        get :bib_items, params: { bib_id: "9965126093506421" }, format: 'json'
        expect(response.status).to be 200
        body = JSON.parse(response.body)
        expect(body["firestone$stacks"].first["sortable_call_number"]).to eq "PS.3558.A62424.B43--2010"
      end

      it "handles oversize call numbers" do
        stub_alma_bib_items(mms_id: "9941598513506421", filename: "9941598513506421_holding_items.json")
        get :bib_items, params: { bib_id: "9941598513506421" }, format: 'json'
        expect(response.status).to be 200
        body = JSON.parse(response.body)
        expect(body["firestone$stacks"].first["sortable_call_number"]).to eq "RA.056627.B7544.2003--OVERSIZE"
      end
    end

    context 'when call number is not handeled by lcsort' do
      before do
        # allow(VoyagerHelpers::Liberator).to receive(:get_items_for_bib).and_return(
        #   "f" => [{ holding_id: 1137735, call_number: "B785.W54xH6.1973", items: [{ id: 1230549, on_reserve: "N", copy_number: 1, item_sequence_number: 1, temp_location: nil, perm_location: "f", enum: nil, chron: nil, barcode: "32101028648937", due_date: nil, patron_group_charged: "GRAD", status: ["Not Charged"] }] }]
        # )
      end

      it 'renders a 200 HTTP response and adds a normalized call number for locator' do
        pending "Replace with Alma"
        get :bib_items, params: { bib_id: '987479' }, format: 'json'
        expect(response.status).to be 200
        expect(response.body).to eq("{\"f\":[{\"holding_id\":1137735,\"call_number\":\"B785.W54xH6.1973\",\"items\":[{\"id\":1230549,\"on_reserve\":\"N\",\"copy_number\":1,\"item_sequence_number\":1,\"temp_location\":null,\"perm_location\":\"f\",\"enum\":null,\"chron\":null,\"barcode\":\"32101028648937\",\"due_date\":null,\"patron_group_charged\":\"GRAD\",\"status\":[\"Not Charged\"]}],\"sortable_call_number\":\"B.0785.W54xH6.1973\"}]}")
      end
    end

    context 'when call number is handeled by lcsort' do
      before do
        # allow(VoyagerHelpers::Liberator).to receive(:get_items_for_bib).and_return(
        #   "f" => [{ holding_id: 1412398, call_number: "UB357.E33.1973", items: [{ id: 1503428, on_reserve: "N", copy_number: 1, item_sequence_number: 1, temp_location: nil, perm_location: "f", enum: nil, chron: nil, barcode: "32101004147094", due_date: nil, status: ["Not Charged", "Missing"] }] }, { holding_id: 5434239, call_number: "UB357.E33.1973", items: [{ id: 4647744, on_reserve: "N", copy_number: 2, item_sequence_number: 1, temp_location: nil, perm_location: "f", enum: nil, chron: nil, barcode: "32101072966698", due_date: nil, patron_group_charged: "GRAD", status: ["Not Charged"] }] }]
        # )
      end

      it 'renders a 200 HTTP response and adds a normalized call number for locator' do
        pending "Replace with Alma"
        get :bib_items, params: { bib_id: '1234567' }, format: 'json'
        expect(response.status).to be 200
        expect(response.body).to eq("{\"f\":[{\"holding_id\":1412398,\"call_number\":\"UB357.E33.1973\",\"items\":[{\"id\":1503428,\"on_reserve\":\"N\",\"copy_number\":1,\"item_sequence_number\":1,\"temp_location\":null,\"perm_location\":\"f\",\"enum\":null,\"chron\":null,\"barcode\":\"32101004147094\",\"due_date\":null,\"status\":[\"Not Charged\",\"Missing\"]}],\"sortable_call_number\":\"UB.0357.E33.1973\"},{\"holding_id\":5434239,\"call_number\":\"UB357.E33.1973\",\"items\":[{\"id\":4647744,\"on_reserve\":\"N\",\"copy_number\":2,\"item_sequence_number\":1,\"temp_location\":null,\"perm_location\":\"f\",\"enum\":null,\"chron\":null,\"barcode\":\"32101072966698\",\"due_date\":null,\"patron_group_charged\":\"GRAD\",\"status\":[\"Not Charged\"]}],\"sortable_call_number\":\"UB.0357.E33.1973\"}]}")
      end
    end

    # a bound-with constituent item will have this response
    context 'when no items are found' do
      it 'renders a 404 HTTP response' do
        stub_alma_bib_items(mms_id: "9920809213506421", status: 400, filename: "not_found_items.json")
        get :bib_items, params: { bib_id: '9920809213506421' }, format: 'json'
        expect(response.status).to be 404
      end
    end
  end

  describe "#availability" do
    before do
      data = { "9922486553506421": { "22117511410006421": {} } }
      allow(adapter).to receive(:get_availability_one).and_return(data)
    end
    it "handles one record" do
      # For now we are just testing that the right call is made inside the controller.
      get :availability, params: { bib_id: "9922486553506421" }, format: :json
      expect(response.body).not_to be_empty
      expect(response.body).to include("22117511410006421")
    end
  end

  describe "#availability_many" do
    before do
      data = {
        "9922486553506421": { "22117511410006421": {} },
        "99122426947506421": { "53469873890006421": {}, "53469873880006421": {} }
      }
      allow(adapter).to receive(:get_availability_many).and_return(data)
    end
    it "handles many records" do
      # For now we are just testing that the right call is made inside the controller.
      get :availability_many, params: { bib_ids: "9922486553506421,99122426947506421" }, format: :json
      expect(response.body).not_to be_empty
      expect(response.body).to include("9922486553506421")
      expect(response.body).to include("99122426947506421")
    end
    it "can get CDL status if requested" do
      get :availability_many, params: { bib_ids: "9922486553506421,99122426947506421", deep: true }, format: :json
      expect(response.body).not_to be_empty
      expect(adapter).to have_received(:get_availability_many).with(ids: anything, deep_check: true)
    end
  end

  describe "#availability_holding" do
    before do
      stub_alma_ids(ids: "not-exist", status: 200, fixture: "not_found")
      stub_alma_ids(ids: "9922486553506421", status: 200)
      stub_alma_holding_items(mms_id: "9922486553506421", holding_id: "22117511410006421", filename: "9922486553506421_holding_items.json")
      stub_alma_holding_items(mms_id: "9922486553506421", holding_id: "not-exist", filename: "not_found_items.json")
      stub_alma_ids(ids: "9922868943506421", status: 200)
      stub_alma_holding_items(mms_id: "9922868943506421", holding_id: "22109192600006421", filename: "not_found_items.json")
      stub_alma_holding_items(mms_id: "9922486553506421", holding_id: "22105104420006421", filename: "record_count_3.json")
      stub_alma_library(library_code: "firestone", location_code: "stacks", body: file_fixture("alma/library_firestone_stacks.json"))
    end

    it "reports record not found for a non-existing bib_id" do
      get :availability_holding, params: { bib_id: "not-exist", holding_id: "not-exist" }, format: :json
      expect(response.status).to eq 404
    end

    it "handles a non-existing holding_id" do
      # It would be nice if we could return 404 in this case but we have no way of
      # distinguishing between a non-existing holding_id and a holding_id with no
      # items. They both return total_count 0 in Alma.
      get :availability_holding, params: { bib_id: "9922486553506421", holding_id: "not-exist" }, format: :json
      expect(response.status).to eq 200
      expect(JSON.parse(response.body).count).to eq 0
    end

    it "reports record not found for a bib_id / holding_id mismatch" do
      # It would be nice if we could return 404 in this case but we have no way of
      # distinguishing between a mismatched holding_id and a holding_id with no
      # items.
      get :availability_holding, params: { bib_id: "9922486553506421", holding_id: "22105104420006421" }, format: :json
      expect(response.status).to eq 200
      expect(JSON.parse(response.body).count).to eq 0
    end

    it "returns valid JSON for a valid bib_id/holding_id" do
      get :availability_holding, params: { bib_id: "9922486553506421", holding_id: "22117511410006421" }, format: :json
      expect(response.status).to eq 200
      expect(JSON.parse(response.body).count).to be 1
    end

    it "handles a holding without items correctly" do
      get :availability_holding, params: { bib_id: "9922868943506421", holding_id: "22109192600006421" }, format: :json
      expect(response.status).to eq 200
      expect(JSON.parse(response.body).count).to eq 0
    end
  end
end
