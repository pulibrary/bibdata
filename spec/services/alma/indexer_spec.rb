require 'rails_helper'

RSpec.describe Alma::Indexer do
  include ActiveJob::TestHelper

  let(:solr_url) { ENV["SOLR_URL"] || "http://#{ENV['lando_marc_liberation_test_solr_conn_host']}:#{ENV['lando_marc_liberation_test_solr_conn_port']}/solr/marc-liberation-core-test" }

  describe "#decompress_file" do
    let(:dump_file) { FactoryBot.create(:dump_file, path: file_path) }
    let(:dump_file_indexer) { Alma::Indexer::DumpFileIndexer.new(dump_file, solr_url: solr_url) }

    context "with a file that doesn't exist" do
      let(:file_path) { 'spec/fixtures/files/alma/do_not_create_me.tar.gz' }

      it 'raises an error' do
        expect { |b| dump_file_indexer.decompress_file(&b) }.to raise_error(Errno::ENOENT)
      end
    end
    context "with a .tar.gz file" do
      let(:file_path) { 'spec/fixtures/files/alma/full_dump/1.xml.tar.gz' }

      it 'yields a block' do
        expect { |b| dump_file_indexer.decompress_file(&b) }.to yield_with_args
      end

      it 'returns an xml file' do
        method_return = dump_file_indexer.decompress_file { |anything| anything }
        expect(method_return).to be_kind_of(Array)
        expect(method_return.first).to be_kind_of(File)
        expect(method_return.first.path).to include('.xml')
        expect(method_return.first.closed?).to be true
      end
    end
    context "with a .gz file" do
      let(:file_path) { 'spec/fixtures/files/scsb/scsb_test_short.xml.gz' }

      it 'yields a block' do
        expect { |b| dump_file_indexer.decompress_file(&b) }.to yield_with_args
      end

      it 'returns a DumpFile' do
        method_return = dump_file_indexer.decompress_file { |anything| anything }
        expect(method_return).to be_kind_of(DumpFile)
      end
    end
  end

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

    it "skips bad utf-8 record but import other records" do
      solr = RSolr.connect(url: solr_url)
      solr.delete_by_query("*:*")

      indexer = described_class.new(solr_url: solr_url)
      file_name = file_fixture("alma/full_dump/three_records_one_bad_utf8.xml")
      Sidekiq::Testing.inline! do
        indexer.index_file(file_name)
      end

      solr.commit
      response = solr.get("select", params: { q: "*:*" })

      # It should have skipped the bad UTF-8 record but kept the other two.
      expect(response['response']['numFound']).to eq 2
    end
  end
end
