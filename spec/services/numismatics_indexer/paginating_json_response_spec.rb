require 'rails_helper'

RSpec.describe NumismaticsIndexer::PaginatingJsonResponse do
  subject(:paginating_response) { described_class.new(url: url, logger: logger) }

  let(:url) { 'http://localhost.localdomain/solr' }
  let(:logger) { instance_double(Logger) }

  describe "#total" do
    let(:total_count) { 1 }
    let(:solr_response) do
      {
        pages: {
          total_count: total_count
        }
      }
    end
    let(:response_body) do
      {
        response: solr_response
      }
    end

    before do
      stub_request(
        :get,
        "#{url}&page=1"
      ).to_return(
        status: 200,
        headers: {
          "Content-Type" => "application/json"
        },
        body: JSON.generate(response_body)
      )
    end

    it "requests the total count for the Solr Documents in response" do
      expect(paginating_response.total).to eq(total_count)
    end
  end
end
