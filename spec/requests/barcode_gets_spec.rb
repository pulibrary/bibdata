require 'rails_helper'
require 'marc'

RSpec.describe 'Barcode Gets', type: :request do
  describe 'GET /barcode/32101070300312' do
    it 'returns a collection of bibliographic records', pending: 'Replace with Alma' do
      get '/barcode/32101070300312'
      expect(response.status).to be(200)
    end
  end

  describe 'GET /barcode/321010702214' do
    it 'returns a 404 when the barcode is not a valid form', pending: 'Replace with Alma' do
      # skipping because while pending it fails and breaks CI
      skip
      get '/barcode/321010702214'
      expect(response.status).to be(404)
    end
  end

  describe 'GET /barcode/' do
    it 'returns an error when no barcode is supplied' do
      get '/barcode/'
      expect(response.status).to be(404)
    end
  end
end
