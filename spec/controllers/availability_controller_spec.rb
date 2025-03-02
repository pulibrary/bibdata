require 'rails_helper'
require 'json'

RSpec.describe AvailabilityController, type: :controller do
  let(:request_headers) { { 'Accept' => 'application/json', 'Accept-Encoding' => 'gzip;q=1.0,deflate;q=0.6,identity;q=0.3', 'api_key' => 'TESTME', 'Content-Type' => 'application/json' } }

  describe '#index with ids param' do
    it 'responds 400 bad request' do
      bib_id = '929437'
      get :index, params: { ids: [bib_id], format: :json }
      expect(response).to have_http_status :bad_request
    end
  end

  describe '#index with id param' do
    it 'response 400 bad request' do
      bib_id = '991227850000541'
      get :index, params: { id: bib_id, format: :json }
      expect(response).to have_http_status :bad_request
    end
  end

  describe '#index with mfhd param' do
    it 'response 400 bad request' do
      holding_id = '282033'
      get :index, params: { mfhd: holding_id, format: :json }
      expect(response).to have_http_status :bad_request
    end
  end

  describe '#index with mfhd_serial param' do
    it 'response 400 bad request' do
      get :index, params: { mfhd_serial: '12345678901', format: :json }
      expect(response).to have_http_status :bad_request
    end
  end

  describe 'scsb bib id' do
    let(:scsb_good_lookup) { ScsbLookup.new }
    let(:scsb_bad_lookup) { ScsbLookup.new }
    let(:scsb_id) { '5270946' }
    let(:no_id) { 'foo' }
    let(:bib_response) do
      {
        '32101055068314':
        {
          itemBarcode: '32101055068314',
          itemAvailabilityStatus: 'Available',
          errorMessage: nil
        }
      }.with_indifferent_access
    end

    it '404 when no item ID exists' do
      stub_request(:post, 'https://test.api.com/sharedCollection/bibAvailabilityStatus')
        .with(body: '{"bibliographicId":"foo","institutionId":"scsb"}',
              headers: request_headers)
        .to_return(status: 404, body: '', headers: {})
      allow(scsb_good_lookup).to receive(:find_by_id).and_return({})
      get :index, params: { scsb_id: no_id, format: :json }
      expect(response).to have_http_status(:not_found)
    end

    it 'returns barcodes and status attached to the id' do
      stub_request(:post, 'https://test.api.com/sharedCollection/bibAvailabilityStatus')
        .with(body: '{"bibliographicId":"5270946","institutionId":"scsb"}',
              headers: request_headers)
        .to_return(status: 200, body: '[{ "itemBarcode": "32101055068314", "itemAvailabilityStatus": "Available", "errorMessage": null}]', headers: {})
      allow(scsb_good_lookup).to receive(:find_by_id).and_return(
        [
          {
            itemBarcode: '32101055068314',
            itemAvailabilityStatus: 'Available',
            errorMessage: nil
          }
        ]
      )
      get :index, params: { scsb_id:, format: :json }
      bib_barcodes = JSON.parse(response.body)
      expect(bib_barcodes).to eq(bib_response)
    end

    it 'returns status Unavailable when SCSB status is Not Available' do
      stub_request(:post, 'https://test.api.com/sharedCollection/bibAvailabilityStatus')
        .with(body: '{"bibliographicId":"5270946","institutionId":"scsb"}',
              headers: request_headers)
        .to_return(status: 200, body: '[{ "itemBarcode": "32101055068314", "itemAvailabilityStatus": "Not Available", "errorMessage": null}]', headers: {})

      get :index, params: { scsb_id:, format: :json }
      bib_barcodes = JSON.parse(response.body)
      expect(bib_barcodes['32101055068314']['itemAvailabilityStatus']).to eq('Unavailable')
    end
  end

  describe 'scsb by barcode' do
    let(:scsb_good_lookup) { ScsbLookup.new }
    let(:scsb_bad_lookup) { ScsbLookup.new }
    let(:scsb_id) { '5270946' }
    let(:no_id) { 'foo' }
    let(:bib_response) do
      {
        '32101055068314':
        {
          itemBarcode: '32101055068314',
          itemAvailabilityStatus: 'Available',
          errorMessage: nil
        },
        '32101055068313':
        {
          itemBarcode: '32101055068313',
          itemAvailabilityStatus: 'Available',
          errorMessage: nil
        }
      }.with_indifferent_access
    end

    it '404 when no item ID exists' do
      stub_request(:post, 'https://test.api.com/sharedCollection/itemAvailabilityStatus')
        .with(body: '{"barcodes":["foo","blah"]}',
              headers: request_headers)
        .to_return(status: 404, body: '', headers: {})
      allow(scsb_good_lookup).to receive(:find_by_barcodes).and_return({})
      get :index, params: { barcodes: %w[foo blah], format: :json }
      expect(response).to have_http_status(:not_found)
    end

    it 'returns barcodes and status attached to the id' do
      stub_request(:post, 'https://test.api.com/sharedCollection/itemAvailabilityStatus')
        .with(body: '{"barcodes":["32101055068314","32101055068313"]}',
              headers: request_headers)
        .to_return(status: 200, body: '[{ "itemBarcode": "32101055068314", "itemAvailabilityStatus": "Available", "errorMessage": null},{ "itemBarcode": "32101055068313", "itemAvailabilityStatus": "Available", "errorMessage": null}]', headers: {})
      allow(scsb_bad_lookup).to receive(:find_by_barcodes).and_return(
        [
          {
            itemBarcode: '32101055068314',
            itemAvailabilityStatus: 'Available',
            errorMessage: nil
          },
          {
            itemBarcode: '32101055068313',
            itemAvailabilityStatus: 'Available',
            errorMessage: nil
          }
        ]
      )
      get :index, params: { barcodes: %w[32101055068314 32101055068313], format: :json }
      bib_barcodes = JSON.parse(response.body)
      expect(bib_barcodes).to eq(bib_response)
    end

    it 'updates barcode status to Unavaible when the SCSB response says Not Available' do
      stub_request(:post, 'https://test.api.com/sharedCollection/itemAvailabilityStatus')
        .with(body: '{"barcodes":["32101055068314","32101055068313"]}',
              headers: request_headers)
        .to_return(status: 200, body: '[{ "itemBarcode": "32101055068314", "itemAvailabilityStatus": "Available", "errorMessage": null},{ "itemBarcode": "32101055068313", "itemAvailabilityStatus": "Not Available", "errorMessage": null}]', headers: {})

      get :index, params: { barcodes: %w[32101055068314 32101055068313], format: :json }
      bib_barcodes = JSON.parse(response.body)

      scsb_barcode_unavailable = bib_barcodes['32101055068313']
      expect(scsb_barcode_unavailable['itemAvailabilityStatus']).to eq('Unavailable')
    end
  end
end
