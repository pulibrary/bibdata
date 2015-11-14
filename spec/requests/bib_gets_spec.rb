require 'rails_helper'
require 'marc'

RSpec.describe "Bibliographic Gets", :type => :request do
  describe "GET /bibliographic/430472/items" do
    it "Properly encoded item records" do
      get '/bibliographic/430472/items'
      expect(response.status).to be(200)
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
      get '/bibliographic/9160439.json'
      bib = JSON.parse(response.body)
      has_959 = bib["fields"].any? {|f| f.has_key?('959')}
      expect(has_959).to be(false)
    end
  end

  describe 'merges 852s and 856s from holding record into bib record' do
    before(:all) do
      get '/bibliographic/7617477.json'
      @ipad_bib_record = JSON.parse(response.body)
    end

    it 'bib includes firestone holding record info coupled with holding id' do
      f_holding_id = '7429805'
      get "/holdings/#{f_holding_id}.json"
      holding = JSON.parse(response.body)
      holding = MARC::Record.new_from_hash(holding)
      eight52 = holding['852'].to_hash
      eight52['852']['subfields'] << {"0"=>f_holding_id}
      eight56 = holding['856'].to_hash
      eight56['856']['subfields'] << {"0"=>f_holding_id}
      expect(@ipad_bib_record['fields']).to include(eight52)
      expect(@ipad_bib_record['fields']).to include(eight56)
    end

    it 'bib includes lewis holding record info coupled with holding id' do
      sci_holding_id = '7429809'
      get "/holdings/#{sci_holding_id}.json"
      holding = JSON.parse(response.body)
      holding = MARC::Record.new_from_hash(holding)
      eight52 = holding['852'].to_hash
      eight52['852']['subfields'] << {"0"=>sci_holding_id}
      eight56 = holding['856'].to_hash
      eight56['856']['subfields'] << {"0"=>sci_holding_id}
      expect(@ipad_bib_record['fields']).to include(eight52)
      expect(@ipad_bib_record['fields']).to include(eight56)
    end
  end
end
