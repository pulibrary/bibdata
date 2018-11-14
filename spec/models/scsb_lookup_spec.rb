require "rails_helper"

RSpec.describe ScsbLookup do
  describe "#find_by_id" do
    before do
      allow(Rails.logger).to receive(:warn)
      stub_request(:post, "https://test.api.com/sharedCollection/bibAvailabilityStatus")
        .with(
          body: "{\"bibliographicId\":\"some_id\",\"institutionId\":\"scsb\"}",
          headers: {
            'Accept' => 'application/json',
            'Accept-Encoding' => 'gzip;q=1.0,deflate;q=0.6,identity;q=0.3',
            'Api-Key' => 'TESTME',
            'Content-Type' => 'application/json',
            'User-Agent' => 'Faraday v0.14.0'
          }
        )
        .to_raise(Faraday::ConnectionFailed)
      # to_return(status: 200, body: "", headers: {})
    end
    it "logs Faraday::ConnectionFailed and returns empty hash" do
      lookup = described_class.new
      expect(lookup.find_by_id("some_id")).to be_empty
      expect(Rails.logger).to have_received(:warn).with("No barcodes could be retrieved for the item: some_id")
    end
  end

  describe "#find_by_barcodes" do
    before do
      allow(Rails.logger).to receive(:warn)
      stub_request(:post, "https://test.api.com/sharedCollection/itemAvailabilityStatus")
        .with(
          body: "{\"barcodes\":[\"some_id\",\"another_id\"]}",
          headers: {
            'Accept' => 'application/json',
            'Accept-Encoding' => 'gzip;q=1.0,deflate;q=0.6,identity;q=0.3',
            'Api-Key' => 'TESTME',
            'Content-Type' => 'application/json',
            'User-Agent' => 'Faraday v0.14.0'
          }
        )
        .to_raise(Faraday::ConnectionFailed)
      # to_return(status: 200, body: "", headers: {})
    end
    it "logs Faraday::ConnectionFailed and returns empty hash" do
      lookup = described_class.new
      expect(lookup.find_by_barcodes(["some_id", "another_id"])).to be_empty
      expect(Rails.logger).to have_received(:warn).with("No items could be retrieved for the barcodes: some_id,another_id")
    end
  end
end
