require 'rails_helper'

RSpec.describe Alma::Indexer do
  include ActiveJob::TestHelper

  let(:solr_url) { ENV["SOLR_URL"] || "http://#{ENV['lando_marc_liberation_test_solr_conn_host']}:#{ENV['lando_marc_liberation_test_solr_conn_port']}/solr/marc-liberation-core-test" }

  describe "#index_file" do
    let(:solr) { RSolr.connect(url: solr_url) }
    let(:indexer) { described_class.new(solr_url: solr_url) }

    before do
      solr.delete_by_query("*:*")
      Sidekiq::Testing.inline! do
        indexer.index_file(file_name)
      end

      solr.commit
    end
    context "a single uncompressed MARC XML file" do
      let(:file_name) { file_fixture("alma/full_dump/2.xml") }

      it "indexes the file" do
        response = solr.get("select", params: { q: "*:*" })
        # There's only one record in 2.xml
        expect(response['response']['numFound']).to eq 1
      end
    end

    context "with deleted records" do
      let(:file_name) { file_fixture("alma/incremental_11_records.xml") }

      it "handles the records" do
        # Indexes a file with 5 non-deleted records
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

    context "with a bad utf-8 record" do
      let(:file_name) { file_fixture("alma/full_dump/three_records_one_bad_utf8.xml") }
      it "skips bad utf-8 record but import other records" do
        response = solr.get("select", params: { q: "*:*" })

        # It should have skipped the bad UTF-8 record but kept the other two.
        expect(response['response']['numFound']).to eq 2
      end
    end
  end
end
