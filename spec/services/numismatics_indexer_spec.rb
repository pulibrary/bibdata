require 'rails_helper'

RSpec.describe NumismaticsIndexer do
  let(:solr_url) { ENV["SOLR_URL"] || "http://#{ENV['lando_marc_liberation_test_solr_conn_host']}:#{ENV['lando_marc_liberation_test_solr_conn_port']}/solr/marc-liberation-core-test" }
  describe ".full_index" do
    it "calls the instance method" do
      mock = instance_double(described_class)
      allow(described_class).to receive(:new).and_return(mock)
      allow(mock).to receive(:full_index)
      described_class.full_index(solr_url: solr_url)
      expect(mock).to have_received(:full_index)
    end
  end

  describe "#full_index" do
    subject(:indexer) { described_class.new(solr_connection: solr_connection) }
    let(:solr_connection) { RSolr.connect(url: solr_url) }

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
      solr = RSolr.connect(url: solr_url)
      solr.delete_by_query("*:*")
      solr.commit

      described_class.full_index(solr_url: solr_url)
      solr.commit
      response = solr.get("select", params: { q: "*:*" })
      expect(response['response']['numFound']).to eq 6
    end

    context "when there's an error retrieving a figgy record" do
      it "logs the record number and continues indexing" do
        stub_figgy_record_error(id: "92fa663d-5758-4b20-8945-cf5a34458e6e")
        allow(Rails.logger).to receive(:warn)

        expect { indexer.full_index }.not_to raise_error

        expect(Rails.logger).to have_received(:warn).with("Failed to retrieve numismatics document from https://figgy.princeton.edu/concern/numismatics/coins/92fa663d-5758-4b20-8945-cf5a34458e6e/orangelight, http status 502")
      end
    end

    # rubocop:disable Style/GuardClause
    context "when there's an error posting a batch to solr" do
      it "retries each individually" do
        solr = RSolr.connect(url: solr_url)
        solr.delete_by_query("*:*")
        solr.commit

        # raise for the first set, allow the first individual retry, raise for
        # the second in dividual retry, allow all the rest
        responses = [:raise, :call, :raise]
        allow(solr_connection).to receive(:add).and_wrap_original do |original, *args|
          v = responses.shift
          if v == :raise
            raise RSolr::Error::Http.new({ uri: "http://example.com" }, nil)
          else
            original.call(*args)
          end
        end
        allow(Rails.logger).to receive(:warn)

        indexer.full_index
        solr.commit
        expect(Rails.logger).to have_received(:warn).once.with(/Failed to index batch, retrying individually, error was: RSolr::Error::Http/)
        expect(Rails.logger).to have_received(:warn).once.with(/Failed to index individual record coin-1148, error was: RSolr::Error::Http/)
        response = solr.get("select", params: { q: "*:*" })
        expect(response['response']['numFound']).to eq 5
      end
    end
    # rubocop:enable Style/GuardClause

    def stub_figgy_record(id:)
      url = "https://figgy.princeton.edu/concern/numismatics/coins/#{id}/orangelight"
      stub_request(:get, url).to_return(body: file_fixture("numismatics/#{id}.json"))
    end

    def stub_figgy_record_error(id:)
      url = "https://figgy.princeton.edu/concern/numismatics/coins/#{id}/orangelight"
      stub_request(:get, url).to_return(status: 502)
    end

    def stub_search_page(page:)
      url = "https://figgy.princeton.edu/catalog.json?f%5Bhuman_readable_type_ssim%5D%5B%5D=Coin&f%5Bstate_ssim%5D%5B%5D=complete&f%5Bvisibility_ssim%5D%5B%5D=open&per_page=100&q=&page=#{page}"
      stub_request(:get, url).to_return(body: file_fixture("numismatics/search_page_#{page}.json"))
    end
  end
end
