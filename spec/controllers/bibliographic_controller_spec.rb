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

  describe '#update' do
    before { skip("Replace with Alma") }
    it 'does not enqueue a job unless the client is authenticated' do
      post :update, params: { bib_id: bib_id }
      expect(response).to redirect_to user_cas_omniauth_authorize_path
    end

    context 'when authenticated as an administrator' do
      login_admin

      it 'enqueues an Index Job for a bib. record using a bib. ID' do
        post :update, params: { bib_id: bib_id }
        expect(response).to redirect_to(index_path)
        expect(flash[:notice]).to be_present
        expect(flash[:notice]).to eq "Reindexing job scheduled for #{bib_id}"
      end
      context 'renders a flash message' do
        let(:bib_record) { nil }
        it 'when record is not found or is suppressed' do
          post :update, params: { bib_id: bib_id }

          expect(response).not_to redirect_to(index_path)
          expect(flash[:notice]).not_to be_present
          expect(response.body).to eq("Record #{bib_id} not found or suppressed")
        end
      end
    end
  end

  describe '#bib' do
    before do
      allow(adapter).to receive(:get_bib_record).and_return(marc_991227850000541)
    end

    it 'renders a marc xml record' do
      get :bib, params: { bib_id: unsuppressed }, format: :xml
      expect(response.body).not_to be_empty
      expect(response.body).to include("record xmlns='http://www.loc.gov/MARC21/slim'")
      expect(response.body).to eq(marc_991227850000541.to_xml.to_s)
    end

    context 'when an error is encountered while querying Voyager' do
      before do
        allow(Rails.logger).to receive(:error)
        allow(adapter).to receive(:get_bib_record).and_raise("it's broken")
      end
      it 'returns a 400 HTTP response and logs an error' do
        get :bib, params: { bib_id: bib_id }

        expect(response.status).to be 400
        expect(Rails.logger).to have_received(:error).with("Failed to retrieve the record using the bib. ID: 1234567: it's broken")
      end
    end
  end

  describe '#bib_jsonld' do
    before do
      allow(adapter).to receive(:get_bib_record).and_return(marc_99226236706421)
      allow(indexer).to receive(:map_record).and_return(solr_doc)
      stub_const("TRAJECT_INDEXER", indexer)
      stub_ezid(shoulder: "88435", blade: "h702qb15q")
      stub_request(:get, "https://figgy.princeton.edu/catalog.json?f%5Bidentifier_tesim%5D%5B0%5D=ark&page=1&q=&rows=1000000")
        .with(
          headers: {
            'Accept' => '*/*',
            'Accept-Encoding' => 'gzip;q=1.0,deflate;q=0.6,identity;q=0.3',
            'User-Agent' => 'Faraday v1.0.1'
          }
        )
        .to_return(status: 200, body: JSON.generate(results))
    end
    context 'when a jsonld is requested' do
      let(:ark) { "ark:/88435/h702qb15q" }
      let(:bib_id) { "99226236706421" }
      let(:docs) do
        [
          {
            id: "7531f427-74a0-4986-ba52-fb3362a591b5",
            internal_resource_tsim: [
              "ScannedResource"
            ],
            internal_resource_ssim: [
              "ScannedResource"
            ],
            internal_resource_tesim: [
              "ScannedResource"
            ],
            identifier_tsim: [
              ark
            ],
            identifier_ssim: [
              ark
            ],
            identifier_tesim: [
              ark
            ],
            source_metadata_identifier_tsim: [
              bib_id
            ],
            source_metadata_identifier_ssim: [
              bib_id
            ],
            source_metadata_identifier_tesim: [
              bib_id
            ]

          }
        ]
      end
      let(:pages) do
        {
          "current_page": 1,
          "next_page": 2,
          "prev_page": nil,
          "total_pages": 1,
          "limit_value": 10,
          "offset_value": 0,
          "total_count": 1,
          "first_page?": true,
          "last_page?": true
        }
      end
      let(:results) do
        {
          "response": {
            "docs": docs,
            "facets": [],
            "pages": pages
          }
        }
      end
      let(:solr_doc) do
        {
          "id" => ["99226236706421"],
          "electronic_access_1display" => ["{\"http://arks.princeton.edu/ark:/88435/h702qb15q\":[\"Table of contents\"]}"]
        }
      end
      let(:indexer) { instance_double(Traject::Indexer) }

      it 'generates JSON-LD' do
        get :bib_jsonld, params: { bib_id: ark_record }, format: :jsonld
        expect(response.body).not_to be_empty
        json_ld = JSON.parse(response.body)
        expect(json_ld).to include 'identifier'
        expect(json_ld['identifier']).to include 'http://arks.princeton.edu/ark:/88435/h702qb15q'
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

    context 'when no items are found' do
      before do
        # allow(VoyagerHelpers::Liberator).to receive(:get_items_for_bib).and_return(nil)
      end

      it 'renders a 404 HTTP response' do
        pending "Replace with Alma"
        get :bib_items, params: { bib_id: '1234567' }, format: 'json'
        expect(response.status).to be 404
      end
    end
  end
end
