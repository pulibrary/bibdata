require 'rails_helper'
require 'marc'

RSpec.describe "Bibliographic Gets", type: :request do
  describe "GET /bibliographic/430472/items" do
    it "Properly encoded item records" do
      stub_voyager_items('430472')
      get '/bibliographic/430472/items'
      expect(response.status).to be(200)
    end
  end

  describe "GET /bibliographic/00000000/items" do
    it "returns an error when the bib record does not exist" do
      allow(VoyagerHelpers::Liberator).to receive(:get_items_for_bib).and_return([])
      get '/bibliographic/00000000/items'
      expect(response.status).to be(404)
    end
  end

  describe "GET /bibliographic/6815537" do
    it "Removes bib 852 when there is no holding record" do
      stub_voyager('6815537')
      get '/bibliographic/6815537.json'
      bib = JSON.parse(response.body)
      has_852 = bib["fields"].any? {|f| f.has_key?('852')}
      expect(has_852).to be(false)
    end
  end

  describe 'retrieving solr json' do
    let(:ark) { "ark:/88435/7d278t10z" }
    let(:bib_id) { "4609321" }
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
          ],

        }
      ]
    end
    let(:pages) do
      {
        "current_page":1,
        "next_page":2,
        "prev_page":nil,
        "total_pages":1,
        "limit_value":10,
        "offset_value":0,
        "total_count":1,
        "first_page?":true,
        "last_page?":true
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

    before do
      stub_request(:get, "https://figgy.princeton.edu/catalog.json?f%5Bidentifier_tesim%5D%5B0%5D=ark&page=1&q=&rows=1000000").to_return(status: 200, body: JSON.generate(results))
    end

    it 'retrieves solr json for a bib record' do
      bib_id = '1234567'
      stub_voyager('1234567')
      get "/bibliographic/#{bib_id}/solr"
      expect(response.status).to be(200)

      solr_doc = JSON.parse(response.body)
      expect(solr_doc['id']).to eq(['1234567'])
    end

    context 'with a bib record which has an ARK' do
      it 'exposes the ARK' do
        bib_id = '10372293'
        stub_voyager('10372293')
        get "/bibliographic/#{bib_id}/solr"
        expect(response.status).to be(200)

        solr_doc = JSON.parse(response.body)
        expect(solr_doc['id']).to eq(['10372293'])

        expect(solr_doc).to have_key('electronic_access_1display')
        electronic_access_links = solr_doc['electronic_access_1display']
        electronic_access = JSON.parse(electronic_access_links.first)
        expect(electronic_access).to include('http://arks.princeton.edu/ark:/88435/dsp015425kd270' => ['arks.princeton.edu'])
      end
    end

    context 'with a bib record which has an ARK in Figgy' do
      it 'exposes a link to the catalog' do
        bib_id = '4765221'
        stub_voyager('4765221')
        stub_ezid(shoulder: "88435", blade: "00000140q")
        get "/bibliographic/#{bib_id}/solr"
        expect(response.status).to be(200)

        solr_doc = JSON.parse(response.body)
        expect(solr_doc['id']).to eq(['4765221'])

        expect(solr_doc).to have_key('electronic_access_1display')
        electronic_access_links = solr_doc['electronic_access_1display']
        electronic_access = JSON.parse(electronic_access_links.first)
        expect(electronic_access).to include('https://catalog.princeton.edu/catalog/4765221#view' => ['Digital content'])

        expect(electronic_access).to have_key('iiif_manifest_paths')
        manifest_paths = electronic_access['iiif_manifest_paths']
        expect(manifest_paths).to include('http://arks.princeton.edu/ark:/88435/00000140q' => 'https://figgy.princeton.edu/concern/scanned_resources/181f7a9d-7e3c-4519-a79f-90113f65a14d/manifest')
      end
    end

    it 'displays an error when the bib record does not exist' do
      stub_voyager('00000000')
      get '/bibliographic/00000000/solr'
      expect(response.status).to be(404)
    end
  end

  describe 'retrieving json+ld' do
    it 'retrieves json+ld for a bib record' do
      stub_voyager('1234567')
      get "/bibliographic/1234567/jsonld"
      expect(response.status).to be(200)
      expect(response.content_type).to eq('application/ld+json')

      json_ld_doc = JSON.parse(response.body)
      expect(json_ld_doc['title']).to eq('@value' => 'Christopher and his kind, 1929-1939', '@language' => 'eng')
    end

    context 'with a bib record which has an ARK' do
      it 'exposes the ARK' do
        bib_id = '10372293'
        stub_voyager('10372293')
        stub_ezid(shoulder: "88435", blade: "dsp015425kd270")
        get "/bibliographic/#{bib_id}/jsonld"
        expect(response.status).to be(200)

        solr_doc = JSON.parse(response.body)
        expect(solr_doc['@id']).to eq('http://www.example.com/bibliographic/10372293')
        expect(solr_doc['identifier']).to eq 'http://arks.princeton.edu/ark:/88435/dsp015425kd270'
      end
    end

    context 'with a bib record which has an ARK for a Figgy resource' do
      it 'exposes the ARK' do
        bib_id = '4609321'
        stub_voyager('4609321')
        stub_ezid(shoulder: "88435", blade: "xp68kg247")
        stub_ezid(shoulder: "88435", blade: "7d278t10z")
        get "/bibliographic/#{bib_id}/jsonld"
        expect(response.status).to be(200)

        solr_doc = JSON.parse(response.body)
        expect(solr_doc['@id']).to eq('http://www.example.com/bibliographic/4609321')
        expect(solr_doc['identifier']).to eq 'http://arks.princeton.edu/ark:/88435/7d278t10z'
      end
    end
  end

  describe "GET /bibliographic/:bib_id" do
    it "returns an error when the bib record does not exist" do
      stub_voyager('00000000')
      get '/bibliographic/00000000'
      expect(response.status).to be(404)
    end

    it "returns xml" do
      stub_voyager('1234567')
      get '/bibliographic/1234567.xml'
      expect(response.status).to be(200)
      expect(response.content_type).to eq('application/xml')
    end
  end

  describe 'index' do
    it 'redirects to holdings' do
      get '/bibliographic?bib_id=1234567&holdings_only=1'
      expect(response).to redirect_to('/bibliographic/1234567/holdings')
    end

    it 'redirects to items' do
      get '/bibliographic?bib_id=1234567&items_only=1'
      expect(response).to redirect_to('/bibliographic/1234567/items')
    end

    it 'redirects to bib' do
      get '/bibliographic?bib_id=1234567'
      expect(response).to redirect_to('/bibliographic/1234567')
    end

    it 'returns an error when a bib id is not provided' do
      get '/bibliographic'
      expect(response.status).to be(404)
    end
  end

  describe 'holdings' do
    it 'provides json' do
      stub_voyager_holdings('1234567')
      get '/bibliographic/1234567/holdings.json' # XXX timeout
      expect(response.content_type).to eq('application/json')
    end

    it 'provides xml' do
      stub_voyager_holdings('1234567')
      get '/bibliographic/1234567/holdings.xml' # XXX timeout
      expect(response.content_type).to eq('application/xml')
    end

    it "returns an error when the bib record does not exist" do
      allow(VoyagerHelpers::Liberator).to receive(:get_holding_records).and_return []
      get '/bibliographic/00000000/holdings'
      expect(response.status).to be(404)
    end
  end

  describe "GET /bibliographic/8637182" do
    it "Removes bib 866" do
      stub_voyager('8637182')
      get '/bibliographic/8637182.json'
      bib = JSON.parse(response.body)
      has_866 = bib["fields"].any? {|f| f.has_key?('866')}
      expect(has_866).to be(false)
    end
  end

  describe '#get_catalog_date added to 959' do

    it 'adds item create_date when bib has associated items' do
      stub_voyager('4461315')
      get '/bibliographic/4461315.json'
      bib = JSON.parse(response.body)
      has_959 = bib["fields"].any? {|f| f.has_key?('959')}
      expect(has_959).to be(true)
    end

    it 'adds item create_date when bib without items is an elf' do
      stub_voyager('491668')
      get '/bibliographic/491668.json'
      bib = JSON.parse(response.body)
      has_959 = bib["fields"].any? {|f| f.has_key?('959')}
      expect(has_959).to be(true)
    end

    it 'does not add item create_date when bib without items is not elf' do
      stub_voyager('4609321')
      get '/bibliographic/4609321.json'
      bib = JSON.parse(response.body)
      has_959 = bib["fields"].any? {|f| f.has_key?('959')}
      expect(has_959).to be(false)
    end
  end

  describe 'holding record info is coupled with holding id in bib record' do
    it 'merges 852s and 856s from holding record into bib record' do
      bib_id = '7617477'
      stub_voyager('7617477')
      get "/bibliographic/#{bib_id}.json"
      ipad_bib_record = JSON.parse(response.body)

      ['7429805', '7429809', '7429811'].each do |id|
        stub_voyager_holding(id)
        get "/holdings/#{id}.json"
        holding = JSON.parse(response.body)
        holding = MARC::Record.new_from_hash(holding)
        eight52 = holding['852'].to_hash
        eight52['852']['subfields'].prepend("0"=>id.to_s)
        eight56 = holding['856'].to_hash
        eight56['856']['subfields'].prepend("0"=>id.to_s)
        expect(ipad_bib_record['fields']).to include(eight52)
        expect(ipad_bib_record['fields']).to include(eight56)

      end
    end

    it 'merges 866s from holding record into bib record when present' do
      bib_id = '4609321'
      stub_voyager('4609321')
      get "/bibliographic/#{bib_id}.json"
      ipad_bib_record = JSON.parse(response.body)

      ['4847980', '4848993'].each do |id|
        stub_voyager_holding(id)
        get "/holdings/#{id}.json"
        holding = JSON.parse(response.body)
        holding = MARC::Record.new_from_hash(holding)
        eight66 = holding['866'].to_hash
        eight66['866']['subfields'].prepend("0"=>id.to_s)
        expect(ipad_bib_record['fields']).to include(eight66)
      end
    end
  end
end

def stub_voyager(bibid)
  f=File.expand_path("../../fixtures/#{bibid}.mrx",__FILE__)
  allow(VoyagerHelpers::Liberator).to receive(:get_bib_record).and_return MARC::XMLReader.new(f).first
end

def stub_voyager_holding(bibid)
  f=File.expand_path("../../fixtures/#{bibid}-holding.xml",__FILE__)
  allow(VoyagerHelpers::Liberator).to receive(:get_holding_record).and_return MARC::XMLReader.new(f).first
end

def stub_voyager_holdings(bibid)
  f=File.expand_path("../../fixtures/#{bibid}-holdings.xml",__FILE__)
  allow(VoyagerHelpers::Liberator).to receive(:get_holding_records).and_return [MARC::XMLReader.new(f).first]
end

def stub_voyager_items(bibid)
  f=File.expand_path("../../fixtures/#{bibid}-items.json",__FILE__)
  allow(VoyagerHelpers::Liberator).to receive(:get_items_for_bib).and_return JSON.parse(File.read(f))
end
