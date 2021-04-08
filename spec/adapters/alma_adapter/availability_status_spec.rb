# require 'rails_helper'

# RSpec.describe AlmaAdapter::AvailabilityStatus do
#   let(:bib_response) { file_fixture("alma/994264203506421.json").read }
#   let(:holding_items_page_1) { file_fixture("alma/994264203506421_2284678120006421_items_page_1.json").read }
#   let(:holding_items_page_2) { file_fixture("alma/994264203506421_2284678120006421_items_page_2.json").read }

#   before do
#     stub_request(:get, "https://api-na.hosted.exlibrisgroup.com/almaws/v1/bibs/994264203506421/holdings/2284678120006421/items?limit=40&offset=0")
#       .with(
#         headers: {
#           'Accept' => 'application/json',
#           'Accept-Encoding' => 'gzip;q=1.0,deflate;q=0.6,identity;q=0.3',
#           'Authorization' => 'apikey TESTME',
#           'Content-Type' => 'application/json',
#           'User-Agent' => 'Ruby'
#         }
#       )
#       .to_return(status: 200, body: holding_items_page_1, headers: { "content-Type" => "application/json" })

#     stub_request(:get, "https://api-na.hosted.exlibrisgroup.com/almaws/v1/bibs/994264203506421/holdings/2284678120006421/items?limit=40")
#       .with(
#         headers: {
#           'Accept' => 'application/json',
#           'Accept-Encoding' => 'gzip;q=1.0,deflate;q=0.6,identity;q=0.3',
#           'Authorization' => 'apikey TESTME',
#           'Content-Type' => 'application/json',
#           'User-Agent' => 'Ruby'
#         }
#       )
#       .to_return(status: 200, body: holding_items_page_1, headers: { "content-Type" => "application/json" })

#     stub_request(:get, "https://api-na.hosted.exlibrisgroup.com/almaws/v1/bibs/994264203506421/holdings/2284678120006421/items")
#       .with(
#         headers: {
#           'Accept' => 'application/json',
#           'Accept-Encoding' => 'gzip;q=1.0,deflate;q=0.6,identity;q=0.3',
#           'Authorization' => 'apikey TESTME',
#           'Content-Type' => 'application/json',
#           'User-Agent' => 'Ruby'
#         }
#       )
#       .to_return(status: 200, body: holding_items_page_1, headers: { "content-Type" => "application/json" })

#     stub_request(:get, "https://api-na.hosted.exlibrisgroup.com/almaws/v1/bibs/994264203506421/holdings/2284678120006421/items?limit=40&offset=40")
#       .with(
#         headers: {
#           'Accept' => 'application/json',
#           'Accept-Encoding' => 'gzip;q=1.0,deflate;q=0.6,identity;q=0.3',
#           'Authorization' => 'apikey TESTME',
#           'Content-Type' => 'application/json',
#           'User-Agent' => 'Ruby'
#         }
#       )
#       .to_return(status: 200, body: holding_items_page_2, headers: { "content-Type" => "application/json" })
#   end

#   describe "#holdings" do
#     context "holding with many items" do
#       it "handles pagination" do
#         json_response = JSON.parse(bib_response)
#         bib = Alma::Bib.new(json_response["bib"].first)
#         status = described_class.new(bib: bib)
#         data = status.holding_item_data(holding_id: "2284678120006421", page_size: 40)
#         expect(data[:items].count).to eq 44
#         expect(data[:total_count]).to eq 44
#       end
#     end
#   end
# end
