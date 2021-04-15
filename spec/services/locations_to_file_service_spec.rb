require 'rails_helper'

RSpec.describe LocationsToFileService, type: :service do
  describe ".call" do
    let(:service) { instance_double(LocationsToFileService) }
    before do
      allow(described_class).to receive(:new).and_return(service)
      allow(service).to receive(:holding_locations_to_file)
      allow(service).to receive(:delivery_locations_to_file)
    end
    it "calls instance methods" do
      described_class.call
      expect(service).to have_received(:holding_locations_to_file)
      expect(service).to have_received(:delivery_locations_to_file)
    end
  end

  describe "#holding_locations_to_file" do
    subject(:service) { described_class.new(base_path: base_path) }
    let(:voyager_alma_mapping) { file_fixture('voyager_alma_mapping.csv') }
    let(:holding_locations) { File.join(base_path, 'holding_locations.json') }
    let(:base_path) { Rails.root.join('tmp', 'locations') }

    before do
      FileUtils.rm_rf(base_path)
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

    it "creates a file with voyager holding locations mapped to alma locations" do
      expect(File).not_to exist(holding_locations)
      service.holding_locations_to_file
      expect(File).to exist(holding_locations)
      expect(File.read(holding_locations)).to include("label": "African American Studies Reading Room (AAS). B-7-B", "alma_library_code": "firestone")
      # expect(File.read(delivery_locations)).to include("label": "African American Studies Reading Room (AAS). B-7-B", "alma_library_code": "firestone")
    end
  end
end
