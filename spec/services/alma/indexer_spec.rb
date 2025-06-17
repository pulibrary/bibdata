require 'rails_helper'

RSpec.describe Alma::Indexer, indexing: true, sidekiq: true do
  let(:solr_url) { ENV.fetch('SOLR_URL', nil) || "http://#{ENV.fetch('lando_bibdata_test_solr_conn_host', nil)}:#{ENV.fetch('lando_bibdata_test_solr_conn_port', nil)}/solr/bibdata-core-test" }

  describe '#index_file' do
    it 'indexes a single uncompressed MARC XML file' do
      solr = RSolr.connect(url: solr_url)
      solr.delete_by_query('*:*')

      indexer = described_class.new(solr_url:)
      file_path = file_fixture('alma/full_dump/2.xml')
      Sidekiq::Testing.inline! do
        indexer.index_file(file_path)
      end

      solr.commit
      response = solr.get('select', params: { q: '*:*' })
      # There's only one record in 2.xml
      expect(response['response']['numFound']).to eq 1
    end

    it 'handles bad indicators' do
      solr = RSolr.connect(url: solr_url)
      solr.delete_by_query('*:*')

      indexer = described_class.new(solr_url:)
      file_path = file_fixture('alma/broken_indicator.xml')
      indexer.index_file(file_path)
    end

    it 'handles records with fields that have no tags' do
      indexer = described_class.new(solr_url:)
      file_path = file_fixture('alma/field_with_no_tag.xml')
      indexer.index_file(file_path)
    end

    it 'handles deleted records' do
      solr = RSolr.connect(url: solr_url)
      solr.delete_by_query('*:*')

      indexer = described_class.new(solr_url:)

      # Indexes a file with 5 non-deleted records
      file_path = file_fixture('alma/incremental_11_records.xml')
      indexer.index_file(file_path)
      solr.commit
      response = solr.get('select', params: { q: '*:*' })
      expect(response['response']['numFound']).to eq 5

      # Forcefully add a record (id=99122238836006421)...
      file_path = file_fixture('alma/incremental_01_record_add.xml')
      indexer.index_file(file_path)
      solr.commit
      response = solr.get('select', params: { q: 'id:99122238836006421' })
      expect(response['response']['numFound']).to eq 1

      # ...and make sure it is deleted
      file_path = file_fixture('alma/incremental_01_record_delete.xml')
      indexer.index_file(file_path)
      solr.commit
      response = solr.get('select', params: { q: 'id:99122238836006421' })
      expect(response['response']['numFound']).to eq 0
    end

    it 'skips bad utf-8 record but import other records' do
      solr = RSolr.connect(url: solr_url)
      solr.delete_by_query('*:*')

      indexer = described_class.new(solr_url:)
      file_path = file_fixture('alma/full_dump/three_records_one_bad_utf8.xml')
      Sidekiq::Testing.inline! do
        indexer.index_file(file_path)
      end

      solr.commit
      response = solr.get('select', params: { q: '*:*' })

      # It should have skipped the bad UTF-8 record but kept the other two.
      expect(response['response']['numFound']).to eq 2
    end

    it 'logs at the info level when it indexes a file successfully' do
      allow(Rails.logger).to receive(:info)
      indexer = described_class.new(solr_url:)
      file_path = file_fixture('alma/full_dump/2.xml')
      Sidekiq::Testing.inline! do
        indexer.index_file(file_path)
      end
      expect(Rails.logger).to have_received(:info).once.with("Successfully indexed file #{file_path}")
    end

    context "with a file that doesn't exist" do
      before do
        allow(Rails.logger).to receive(:error)
      end

      let(:file_path) { 'spec/fixtures/files/alma/do_not_create_me.tar.gz' }

      it 'raises an error' do
        indexer = described_class.new(solr_url:)
        expected_error_snippet = %r{No such file or directory @ rb_sysopen - spec/fixtures/files/alma/do_not_create_me.tar.gz}
        Sidekiq::Testing.inline! do
          expect { indexer.index_file(file_path) }.to raise_error(RuntimeError, expected_error_snippet)
        end
        expect(Rails.logger).to have_received(:error).once.with(expected_error_snippet)
      end
    end
  end
end
