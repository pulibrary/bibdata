require 'rails_helper'

RSpec.describe Alma::Indexer do
  include ActiveJob::TestHelper

  let(:solr_url) { ENV["SOLR_URL"] || "http://#{ENV['lando_marc_liberation_test_solr_conn_host']}:#{ENV['lando_marc_liberation_test_solr_conn_port']}/solr/marc-liberation-core-test" }

  describe "#index_file" do
    it "indexes a single uncompressed MARC XML file" do
      solr = RSolr.connect(url: solr_url)
      solr.delete_by_query("*:*")

      indexer = described_class.new(solr_url: solr_url)
      file_name = file_fixture("alma/full_dump/2.xml")
      Sidekiq::Testing.inline! do
        indexer.index_file(file_name)
      end

      solr.commit
      response = solr.get("select", params: { q: "*:*" })
      # There's only one record in 2.xml
      expect(response['response']['numFound']).to eq 1
    end

    it "handles deleted records" do
      solr = RSolr.connect(url: solr_url)
      solr.delete_by_query("*:*")

      indexer = described_class.new(solr_url: solr_url)

      # Indexes a file with 5 non-deleted records
      file_name = file_fixture("alma/incremental_11_records.xml")
      indexer.index_file(file_name)
      solr.commit
      response = solr.get("select", params: { q: "*:*" })
      expect(response['response']['numFound']).to eq 5

      # Forcefully add a record (id=99122238836006421)...
      file_name = file_fixture("alma/incremental_01_record_add.xml")
      indexer.index_file(file_name)
      solr.commit
      response = solr.get("select", params: { q: "id:99122238836006421" })
      expect(response['response']['numFound']).to eq 1

      # ...and make sure it is deleted
      file_name = file_fixture("alma/incremental_01_record_delete.xml")
      indexer.index_file(file_name)
      solr.commit
      response = solr.get("select", params: { q: "id:99122238836006421" })
      expect(response['response']['numFound']).to eq 0
    end
  end
end
