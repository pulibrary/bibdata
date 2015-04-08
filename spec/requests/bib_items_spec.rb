require 'rails_helper'

RSpec.describe "Bibliographic Items", :type => :request do
  describe "GET /bibliographic/430472/items" do
    it "Properly encoded item records" do
      get '/bibliographic/430472/items'
      expect(response.status).to be(200)
    end
  end
end
