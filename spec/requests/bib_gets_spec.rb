require 'rails_helper'

RSpec.describe "Bibliographic Gets", :type => :request do
  describe "GET /bibliographic/430472/items" do
    it "Properly encoded item records" do
      get '/bibliographic/430472/items'
      expect(response.status).to be(200)
    end
  end

  describe "GET /bibliographic/3478680" do
  	it "Removes bib 852 when there is no holding record" do
  		get '/bibliographic/3478680.json'
  		bib = JSON.parse(response.body)
  		has_852 = false
  		bib["fields"].each {|f| has_852 = true if f.has_key?('852')}
  		expect(has_852).to be(false)
  	end
	end

end