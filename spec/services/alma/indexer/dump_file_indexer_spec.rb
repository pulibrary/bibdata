require 'rails_helper'

RSpec.describe Alma::Indexer::DumpFileIndexer, :sidekiq do
  let(:solr_url) { ENV.fetch('SOLR_URL', nil) || "http://#{ENV.fetch('lando_bibdata_test_solr_conn_host', nil)}:#{ENV.fetch('lando_bibdata_test_solr_conn_port', nil)}/solr/bibdata-core-test" }
  let(:file_path) { 'spec/fixtures/files/scsb/scsb_test_short.xml.gz' }
  let(:dump_file) { FactoryBot.create(:dump_file, path: file_path) }
  let(:dump_file_indexer) { described_class.new(dump_file, solr_url:) }

  around do |example|
    should_backup_file = File.exist? file_path
    FileUtils.cp(file_path, "#{file_path}.backup") if should_backup_file
    example.run
    FileUtils.mv("#{file_path}.backup", file_path) if should_backup_file
  end

  describe '#decompress_file' do
    context 'with a .tar.gz file' do
      let(:file_path) { 'spec/fixtures/files/alma/full_dump/1.xml.tar.gz' }

      it 'yields a block' do
        expect { |b| dump_file_indexer.decompress_file(&b) }.to yield_with_args
      end

      it 'returns an xml file' do
        method_return = dump_file_indexer.decompress_file { |anything| anything }
        expect(method_return).to be_a(Array)
        expect(method_return.first).to be_a(File)
        expect(method_return.first.path).to include('.xml')
        expect(method_return.first.closed?).to be true
      end
    end

    context 'with a .gz file' do
      it 'yields a block' do
        expect { |b| dump_file_indexer.decompress_file(&b) }.to yield_with_args
      end

      it 'returns a DumpFile' do
        method_return = dump_file_indexer.decompress_file { |anything| anything }
        expect(method_return).to be_a(DumpFile)
      end
    end
  end

  describe '#index!' do
    context 'with a .tar.gz file' do
      let(:file_path) { 'spec/fixtures/files/alma/full_dump/2.xml.tar.gz' }

      it 'indexes a single compressed MARC XML file' do
        solr = RSolr.connect(url: solr_url)
        solr.delete_by_query('*:*')

        allow(dump_file_indexer).to receive(:decompress_file).and_call_original
        allow(dump_file).to receive(:tar_decompress_file).and_call_original
        allow(dump_file).to receive(:zip).and_call_original
        Sidekiq::Testing.inline! do
          dump_file_indexer.index!
        end
        expect(dump_file_indexer).to have_received(:decompress_file)
        expect(dump_file).to have_received(:tar_decompress_file)
        expect(dump_file).not_to have_received(:zip)
        solr.commit
        response = solr.get('select', params: { q: '*:*' })
        # There's only one record in 2.xml
        expect(response['response']['numFound']).to eq 1
      end
    end

    context 'with a .gz file' do
      it 'indexes a single compressed MARC XML file' do
        solr = RSolr.connect(url: solr_url)
        solr.delete_by_query('*:*')

        allow(dump_file_indexer).to receive(:decompress_file).and_call_original
        allow(dump_file).to receive(:tar_decompress_file).and_call_original
        allow(dump_file).to receive(:zip).and_call_original
        Sidekiq::Testing.inline! do
          dump_file_indexer.index!
        end
        expect(dump_file_indexer).to have_received(:decompress_file)
        expect(dump_file).not_to have_received(:tar_decompress_file)
        expect(dump_file).to have_received(:zip)

        solr.commit
        response = solr.get('select', params: { q: '*:*' })
        # There are two records in scsb_test_short.xml.gz
        expect(response['response']['numFound']).to eq 2
      end
    end
  end
end
