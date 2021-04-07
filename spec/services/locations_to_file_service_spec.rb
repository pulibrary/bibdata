require 'rails_helper'

RSpec.describe LocationsToFileService, type: :service do
  subject(:service) { described_class.new }
  let(:bibdata_holding_locations) { file_fixture('bibdata_holding_locations.json') }
  let(:bibdata_delivery_locations) { file_fixture('bibdata_delivery_locations.json') }
  let(:voyager_alma_mapping) { file_fixture('voyager_alma_mapping.csv') }
  let(:holding_locations) { file_fixture('holding_locations.json') }

  # after do
  #   FileUtils.rm(bibdata_holding_locations) if File.exist?(bibdata_holding_locations)
  #   FileUtils.rm(bibdata_delivery_locations) if File.exist?(bibdata_delivery_locations)
  #   FileUtils.rm(voyager_alma_mapping) if File.exist?(voyager_alma_mapping)
  # end

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

  describe "#holding_locations_to_file" do
    it "creates a file with voyager holding locations mapped to alma locations" do
      # service.holding_locations_to_file
      # expect(File.read(holding_locations)).to include("label": "African American Studies Reading Room (AAS). B-7-B", "alma_library_code": "firestone")
    end
  end
end
