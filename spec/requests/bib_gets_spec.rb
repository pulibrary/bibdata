require 'rails_helper'
require 'marc'

RSpec.describe "Bibliographic Gets", :type => :request do
  describe "GET /bibliographic/430472/items" do
    it "Properly encoded item records" do
      get '/bibliographic/430472/items'
      expect(response.status).to be(200)
    end
  end

  describe "GET /bibliographic/00000000/items" do
    it "returns an error when the bib record does not exist" do
      get '/bibliographic/00000000/items'
      expect(response.status).to be(404)
    end
  end

  describe "GET /bibliographic/6815537" do
    it "Removes bib 852 when there is no holding record" do
      get '/bibliographic/6815537.json'
      bib = JSON.parse(response.body)
      has_852 = bib["fields"].any? {|f| f.has_key?('852')}
      expect(has_852).to be(false)
    end
  end

  describe 'retrieving solr json' do
    it 'retrieves solr json for a bib record' do
      bib_id = '1234567'
      get "/bibliographic/#{bib_id}/solr"
      expect(response.status).to be(200)

      solr_doc = JSON.parse(response.body)
      expect(solr_doc['id']).to eq(['1234567'])
    end

    it 'displays an error when the bib record does not exist' do
      get '/bibliographic/00000000/solr'
      expect(response.status).to be(404)
    end
  end

  describe 'retrieving json+ld' do
    it 'retrieves json+ld for a bib record' do
      get "/bibliographic/1234567/jsonld"
      expect(response.status).to be(200)
      expect(response.content_type).to eq('application/ld+json')

      json_ld_doc = JSON.parse(response.body)
      expect(json_ld_doc['title']).to eq({'@value' => 'Christopher and his kind, 1929-1939 /', '@language' => 'eng'})
    end
  end

  describe "GET /bibliographic/:bib_id" do
    it "returns an error when the bib record does not exist" do
      get '/bibliographic/00000000'
      expect(response.status).to be(404)
    end

    it "returns xml" do
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
      get '/bibliographic/1234567/holdings.json'
      expect(response.content_type).to eq('application/json')
    end

    it 'provides xml' do
      get '/bibliographic/1234567/holdings.xml'
      expect(response.content_type).to eq('application/xml')
    end

    it "returns an error when the bib record does not exist" do
      get '/bibliographic/00000000/holdings'
      expect(response.status).to be(404)
    end
  end

  describe "GET /bibliographic/8637182" do
    it "Removes bib 866" do
      get '/bibliographic/8637182.json'
      bib = JSON.parse(response.body)
      has_866 = bib["fields"].any? {|f| f.has_key?('866')}
      expect(has_866).to be(false)
    end
  end

  describe '#get_catalog_date added to 959' do

    it 'adds item create_date when bib has associated items' do
      get '/bibliographic/4461315.json'
      bib = JSON.parse(response.body)
      has_959 = bib["fields"].any? {|f| f.has_key?('959')}
      expect(has_959).to be(true)
    end

    it 'adds item create_date when bib without items is an elf' do
      get '/bibliographic/491668.json'
      bib = JSON.parse(response.body)
      has_959 = bib["fields"].any? {|f| f.has_key?('959')}
      expect(has_959).to be(true)
    end

    it 'does not add item create_date when bib without items is not elf' do
      get '/bibliographic/4609321.json'
      bib = JSON.parse(response.body)
      has_959 = bib["fields"].any? {|f| f.has_key?('959')}
      expect(has_959).to be(false)
    end
  end

  describe 'holding record info is coupled with holding id in bib record' do
    it 'merges 852s and 856s from holding record into bib record' do
      bib_id = '7617477'
      get "/bibliographic/#{bib_id}.json"
      ipad_bib_record = JSON.parse(response.body)

      holding_ids = VoyagerHelpers::Liberator.send(:get_bib_mfhd_ids, bib_id)
      holding_ids.each do |id|
        get "/holdings/#{id}.json"
        holding = JSON.parse(response.body)
        holding = MARC::Record.new_from_hash(holding)
        eight52 = holding['852'].to_hash
        eight52['852']['subfields'].prepend({"0"=>id.to_s})
        eight56 = holding['856'].to_hash
        eight56['856']['subfields'].prepend({"0"=>id.to_s})
        expect(ipad_bib_record['fields']).to include(eight52)
        expect(ipad_bib_record['fields']).to include(eight56)

      end
    end

    it 'merges 866s from holding record into bib record when present' do
      bib_id = '4609321'
      get "/bibliographic/#{bib_id}.json"
      ipad_bib_record = JSON.parse(response.body)

      holding_ids = VoyagerHelpers::Liberator.send(:get_bib_mfhd_ids, bib_id)
      holding_ids.each do |id|
        get "/holdings/#{id}.json"
        holding = JSON.parse(response.body)
        holding = MARC::Record.new_from_hash(holding)
        eight66 = holding['866'].to_hash
        eight66['866']['subfields'].prepend({"0"=>id.to_s})
        expect(ipad_bib_record['fields']).to include(eight66)
      end
    end
  end
end
