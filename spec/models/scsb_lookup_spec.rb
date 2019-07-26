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

  describe "#scsb_response_json" do
    let(:lookup) { described_class.new }

    context "when the SCSB service encounters an error" do
      let(:scsb_response) { instance_double(ActionDispatch::Response) }
      let(:json_response) { lookup.scsb_response_json(scsb_response) }

      before do
        allow(Rails.logger).to receive(:error)
        allow(scsb_response).to receive(:body)
        allow(scsb_response).to receive(:status).and_return(500)
      end

      it "logs the error and returns an empty Hash" do
        expect(json_response).to eq({})
        expect(Rails.logger).to have_received(:error).with(/The request to the SCSB server failed/)
      end
    end

    context "when the SCSB service endpoint returns non-JSON as a response" do
      let(:scsb_response) { instance_double(ActionDispatch::Response) }
      let(:scsb_response_body) { "{invalid" }
      let(:json_response) { lookup.scsb_response_json(scsb_response) }

      before do
        allow(Rails.logger).to receive(:error)
        allow(scsb_response).to receive(:body).and_return(scsb_response_body)
        allow(scsb_response).to receive(:status).and_return(200)
      end

      it "logs the error and returns an empty Hash" do
        expect(json_response).to eq({})
        expect(Rails.logger).to have_received(:error).with("Failed to parse the response from the SCSB server: {invalid")
      end
    end
  end

  describe "#parse_scsb_message" do
    let(:lookup) { described_class.new }

    context "when the SCSB service endpoint returns non-JSON as a response" do
      let(:scsb_response) { "{invalid" }
      let(:parsed) { lookup.parse_scsb_message(scsb_response) }

      before do
        allow(Rails.logger).to receive(:error)
      end

      it "logs the error and returns an empty Hash" do
        expect(parsed).to eq({})
        expect(Rails.logger).to have_received(:error).with("Failed to parse a message from the SCSB server: {invalid")
      end
    end
  end
end
