require 'rails_helper'

RSpec.describe NumismaticsIndexer do
  describe "#full_index" do
    before do
      stub_search_page(page: 1)
      stub_search_page(page: 2)
      stub_figgy_record(id: "8be8980d-20b8-454e-9431-1aa5bcb89fde")
      stub_figgy_record(id: "bfd72e8a-817f-4412-a7fa-e38047e17c29")
      stub_figgy_record(id: "92fa663d-5758-4b20-8945-cf5a34458e6e")
      stub_figgy_record(id: "62b33c0d-d43a-44fd-a035-6490d25a2132")
      stub_figgy_record(id: "d827dc9f-e857-4868-b056-34fc92894e4e")
      stub_figgy_record(id: "84220cd5-0815-4f01-82a3-704a15835e77")
    end

    it "indexes all the items from the figgy numismatics collection" do
      solr_url = ENV["SOLR_URL"] || "http://#{ENV['lando_marc_liberation_test_solr_conn_host']}:#{ENV['lando_marc_liberation_test_solr_conn_port']}/solr/marc-liberation-core-test"
      solr = RSolr.connect(url: solr_url)
      solr.delete_by_query("*:*")
      solr.commit

      indexer = described_class.new(solr_url: solr_url)
      indexer.full_index
      solr.commit
      response = solr.get("select", params: { q: "*:*" })
      expect(response['response']['numFound']).to eq 6
    end

    def stub_figgy_record(id:)
      url = "https://figgy.princeton.edu/concern/numismatics/coins/#{id}/orangelight"
      stub_request(:get, url).to_return(body: file_fixture("numismatics/#{id}.json"))
    end

    def stub_search_page(page:)
      url = "https://figgy.princeton.edu/catalog.json?f%5Bhuman_readable_type_ssim%5D%5B%5D=Coin&f%5Bstate_ssim%5D%5B%5D=complete&f%5Bvisibility_ssim%5D%5B%5D=open&per_page=100&q=&page=#{page}"
      stub_request(:get, url).to_return(body: file_fixture("numismatics/search_page_#{page}.json"))
    end
  end
end
