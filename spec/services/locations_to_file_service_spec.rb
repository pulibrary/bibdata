require 'rails_helper'

RSpec.describe LocationsToFileService do
  before do
    stub_request(:get, "https://bibdata.princeton.edu/locations/holding_locations.json")
      .to_return(status: 200, body: file_fixture("alma/bibdata_holding_locations.json"), headers: {
                   'Accept-Encoding' => 'gzip;q=1.0,deflate;q=0.6,identity;q=0.3',
                   'Content-Type' => 'application/xml;charset=UTF-8',
                   'Accept' => 'application/xml',
                   'User-Agent' => 'Faraday v1.0.1'
                 })

    stub_request(:get, "https://bibdata.princeton.edu/locations/delivery_locations.json")
      .to_return(status: 200, body: file_fixture("alma/bibdata_delivery_locations.json"), headers: {
                   'Accept-Encoding' => 'gzip;q=1.0,deflate;q=0.6,identity;q=0.3',
                   'Content-Type' => 'application/xml;charset=UTF-8',
                   'Accept' => 'application/xml',
                   'User-Agent' => 'Faraday v1.0.1'
                 })

    stub_request(:get, "https://bibdata.princeton.edu/locations/holding_locations/aas.json")
      .to_return(status: 200, body: file_fixture("alma/holding_location_aas.json"), headers: {
                   'Accept-Encoding' => 'gzip;q=1.0,deflate;q=0.6,identity;q=0.3',
                   'Content-Type' => 'application/xml;charset=UTF-8',
                   'Accept' => 'application/xml',
                   'User-Agent' => 'Faraday v1.0.1'
                 })
    stub_request(:get, "https://bibdata.princeton.edu/locations/holding_locations/anxa.json")
      .to_return(status: 200, body: file_fixture("alma/holding_location_anxa.json"), headers: {
                   'Accept-Encoding' => 'gzip;q=1.0,deflate;q=0.6,identity;q=0.3',
                   'Content-Type' => 'application/xml;charset=UTF-8',
                   'Accept' => 'application/xml',
                   'User-Agent' => 'Faraday v1.0.1'
                 })
  end

  let(:service) { described_class.new(base_path: base_path) }
  let(:voyager_alma_mapping) { file_fixture('voyager_alma_mapping.csv') }
  let(:holding_locations) { File.join(base_path, 'holding_locations.json') }
  let(:delivery_locations) { File.join(base_path, 'delivery_locations.json') }
  let(:base_path) { Rails.root.join('tmp', 'locations') }

  describe ".call" do
    before do
      FileUtils.rm_rf(base_path)
      allow(described_class).to receive(:new).and_return(service)
    end
    it "creates holding and delivery locations json files with voyager holding locations mapped to alma locations" do
      expect(File).not_to exist(holding_locations)
      expect(File).not_to exist(delivery_locations)
      described_class.call
      expect(File).to exist(holding_locations)
      expect(File).to exist(delivery_locations)
    end
  end
end
