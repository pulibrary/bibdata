require 'rails_helper'

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

end
