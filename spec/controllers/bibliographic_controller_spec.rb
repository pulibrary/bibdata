require 'rails_helper'

RSpec.describe BibliographicController, type: :controller do
  render_views
  let(:bib_id) { '1234567' }
  let(:bib_record) { instance_double(MARC::Record) }
  let(:file_path) { Rails.root.join('spec', 'fixtures', "#{bib_id}.mrx") }
  let(:bib_record_xml) { File.read(file_path) }

  before do
    allow(bib_record).to receive(:to_xml).and_return bib_record_xml
    allow(VoyagerHelpers::Liberator).to receive(:get_bib_record).and_return bib_record
  end

  describe '#update' do
    it 'does not enqueue a job unless the client is authenticated' do
      post :update, params: { bib_id: bib_id }
      expect(response).to redirect_to user_cas_omniauth_authorize_path
    end

    context 'when authenticated as an administrator' do
      login_admin

      it 'enqueues an Index Job for a bib. record using a bib. ID', unless: !ENV['CI'].nil? do
        post :update, params: { bib_id: bib_id }
        expect(response).to redirect_to(index_path)
        expect(flash[:notice]).to be_present
        expect(flash[:notice]).to eq "Reindexing job scheduled for #{bib_id}"
      end
    end
  end

  describe '#bib' do
    let(:bib_id) { '10002695' }
    let(:bib_record) do
      MARC::XMLReader.new(file_path.to_s).first
    end
    let(:ark) { "ark:/88435/d504rp938" }
    let(:docs) do
      [
        {
          id: "b65cd851-ef01-45f2-b5bd-28c6616574ca",
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
        "id" => ["10002695"],
        "electronic_access_1display" => ["{\"http://arks.princeton.edu/ark:/88435/d504rp938\":[\"Table of contents\"]}"]
      }
    end
    let(:indexer) { instance_double(Traject::Indexer) }
    before do
      stub_request(:get, "https://figgy.princeton.edu/catalog.json?f%5Bidentifier_tesim%5D%5B0%5D=ark&page=1&q=&rows=1000000").to_return(status: 200, body: JSON.generate(results))
      allow(indexer).to receive(:map_record).and_return(solr_doc)
      stub_const("TRAJECT_INDEXER", indexer)
      stub_ezid(shoulder: "88435", blade: "d504rp938")
    end

    it 'generates JSON-LD' do
      get :bib_jsonld, params: { bib_id: bib_id }

      expect(response.body).not_to be_empty
      json_ld = JSON.parse(response.body)
      expect(json_ld).to include 'identifier'
      expect(json_ld['identifier']).to include 'http://arks.princeton.edu/ark:/88435/d504rp938'
    end

    context 'when an error is encountered while querying Voyager' do
      before do
        class OCIError < StandardError; end if ENV['CI']
        allow(Rails.logger).to receive(:error)
        allow(VoyagerHelpers::Liberator).to receive(:get_bib_record).and_raise(OCIError, 'ORA-01722: invalid number')
      end
      after do
        Object.send(:remove_const, :OCIError) if ENV['CI']
      end
      it 'returns a 400 HTTP response and logs an error' do
        get :bib, params: { bib_id: bib_id }

        expect(response.status).to be 400
        expect(Rails.logger).to have_received(:error).with('Failed to retrieve the Voyager record using the bib. ID: 10002695: ORA-01722: invalid number')
      end
    end
  end
end
