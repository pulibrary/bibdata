require 'rails_helper'

RSpec.describe Alma::Indexer do
  include ActiveJob::TestHelper
  describe "#full_reindex!" do
    it "gets the latest full dump tar files, unzips it, and indexes all the contained files" do
      event = FactoryBot.create(:full_dump_event)
      solr_url = ENV["SOLR_URL"] || "http://#{ENV['lando_marc_liberation_test_solr_conn_host']}:#{ENV['lando_marc_liberation_test_solr_conn_port']}/solr/marc-liberation-core-test"
      stub_request(:get, "http://www.example.com/dump_files/#{event.dump.dump_files[0].id}")
        .to_return(status: 200, body: file_fixture("alma/full_dump/1.xml.tar.gz").read, headers: {})
      stub_request(:get, "http://www.example.com/dump_files/#{event.dump.dump_files[1].id}")
        .to_return(status: 200, body: file_fixture("alma/full_dump/2.xml.tar.gz").read, headers: {})
      solr = RSolr.connect(url: solr_url)
      solr.delete_by_query("*:*")

      indexer = described_class.new(solr_url: solr_url)
      Sidekiq::Testing.inline! do
        indexer.full_reindex!
      end

      solr.commit
      response = solr.get("select", params: { q: "*:*" })
      # There's one record in 1.xml, and one record in 2.xml
      expect(response['response']['numFound']).to eq 2
    end
    it "works even if there's no XML extension" do
      event = FactoryBot.create(:full_dump_event)
      solr_url = ENV["SOLR_URL"] || "http://#{ENV['lando_marc_liberation_test_solr_conn_host']}:#{ENV['lando_marc_liberation_test_solr_conn_port']}/solr/marc-liberation-core-test"
      stub_request(:get, "http://www.example.com/dump_files/#{event.dump.dump_files[0].id}")
        .to_return(status: 200, body: file_fixture("alma/full_dump/1.tar.gz").read, headers: {})
      stub_request(:get, "http://www.example.com/dump_files/#{event.dump.dump_files[1].id}")
        .to_return(status: 200, body: file_fixture("alma/full_dump/2.tar.gz").read, headers: {})
      solr = RSolr.connect(url: solr_url)
      solr.delete_by_query("*:*")

      indexer = described_class.new(solr_url: solr_url)
      Sidekiq::Testing.inline! do
        indexer.full_reindex!
      end

      solr.commit
      response = solr.get("select", params: { q: "*:*" })
      # There's one record in 1.xml, and one record in 2.xml
      expect(response['response']['numFound']).to eq 2
    end
  end

  describe "#index_file" do
    it "indexes a single uncompressed MARC XML file" do
      solr_url = ENV["SOLR_URL"] || "http://#{ENV['lando_marc_liberation_test_solr_conn_host']}:#{ENV['lando_marc_liberation_test_solr_conn_port']}/solr/marc-liberation-core-test"
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
      solr_url = ENV["SOLR_URL"] || "http://#{ENV['lando_marc_liberation_test_solr_conn_host']}:#{ENV['lando_marc_liberation_test_solr_conn_port']}/solr/marc-liberation-core-test"
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

  describe "incremental_index!" do
    it "indexes a dump's files" do
      # url = Rails.application.config.solr['url']
      solr_url = ENV["SOLR_URL"] || "http://#{ENV['lando_marc_liberation_test_solr_conn_host']}:#{ENV['lando_marc_liberation_test_solr_conn_port']}/solr/marc-liberation-core-test"
      solr = RSolr.connect(url: solr_url)
      solr.delete_by_query("*:*")
      solr.commit

      dump = FactoryBot.create(:incremental_dump)
      indexer = described_class.new(solr_url: solr_url)
      Sidekiq::Testing.inline! do
        indexer.incremental_index!(dump)
        # Have to manually call batch callbacks
        IncrementalIndexJob.on_success(Sidekiq::BatchSet.new.to_a.last, "dump_id" => dump.id)
      end
      solr.commit

      # expect solr to have stuff
      response = solr.get("select", params: { q: "*:*" })
      expect(response['response']['numFound']).to eq 7

      expect(DumpFile.done.size).to eq 2
      expect(Dump.last).to be_done
    end
  end
end
