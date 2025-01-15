require 'rails_helper'
require 'marc'

RSpec.describe 'Barcode Gets', type: :request do
  describe 'GET /barcode/32101076720315/scsb' do
    it 'returns a collection of bibliographic records' do
      stub_alma_item_barcode(mms_id: '9958708973506421', item_id: '23178060180006421', holding_id: '22178060190006421', barcode: '32101076720315')
      stub_sru('alma.mms_id=9958708973506421', '9958708973506421')
      stub_alma_ids(ids: '9958708973506421', status: 200, fixture: '9958708973506421')
      stub_alma_holding(mms_id: '9958708973506421', holding_id: '22178060190006421')
      get '/barcode/32101076720315/scsb'
      expect(response.status).to be(200)
    end
  end

  describe 'GET /barcode/32101037077862123456/scsb' do
    it 'returns a 404 when the barcode is not a valid form' do
      stub_request(:get, 'https://api-na.hosted.exlibrisgroup.com/almaws/v1/items?item_barcode=32101037077862123456')
        .to_return(status: 404, body: '', headers: {})
      get '/barcode/32101037077862123456/scsb'
      expect(response.status).to be(404)
    end
  end
end
