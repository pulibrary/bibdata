require 'rails_helper'

RSpec.describe Index::NumismaticsJob do
  let(:solr_url) { ENV.fetch('SOLR_URL', nil) || "http://#{ENV.fetch('lando_bibdata_test_solr_conn_host', nil)}:#{ENV.fetch('lando_bibdata_test_solr_conn_port', nil)}/solr/bibdata-core-test" }

  before do
    stub_search_page(page: 1)
    stub_search_page(page: 2)
    stub_figgy_record(id: '8be8980d-20b8-454e-9431-1aa5bcb89fde')
    stub_figgy_record(id: 'bfd72e8a-817f-4412-a7fa-e38047e17c29')
    stub_figgy_record(id: '92fa663d-5758-4b20-8945-cf5a34458e6e')
    stub_figgy_record(id: '62b33c0d-d43a-44fd-a035-6490d25a2132')
    stub_figgy_record(id: 'd827dc9f-e857-4868-b056-34fc92894e4e')
    stub_figgy_record(id: '84220cd5-0815-4f01-82a3-704a15835e77')
  end

  around do |example|
    Sidekiq::Testing.inline! do
      Sidekiq::Testing.server_middleware do |chain|
        chain.add Sidekiq::Batch::Server
      end
      example.run
      Sidekiq::Testing.server_middleware do |chain|
        chain.remove Sidekiq::Batch::Server
      end
    end
  end

  context 'with many Solr documents' do
    let(:solr_connection) { RSolr.connect(url: solr_url) }
    let(:numismatics_indexer) { NumismaticsIndexer.new(solr_connection:, progressbar: false, logger: Rails.logger) }

    before do
      allow(NumismaticsIndexer).to receive(:new).and_return(numismatics_indexer)
      allow(RSolr).to receive(:connect).and_return(solr_connection)
    end

    it 'enqueues a job for each batch of Solr documents' do
      allow(Index::NumismaticsBatchJob).to receive(:perform_async).and_call_original
      allow(numismatics_indexer).to receive(:index_in_chunks).and_call_original
      allow(solr_connection).to receive(:commit).and_call_original
      described_class.perform_async(solr_url, 2)
      expect(Index::NumismaticsBatchJob).to have_received(:perform_async).exactly(3).times
      expect(numismatics_indexer).to have_received(:index_in_chunks).exactly(3).times
      expect(solr_connection).to have_received(:commit).once
    end
  end

  it 'logs to the rails logger' do
    stub_figgy_record_error(id: '92fa663d-5758-4b20-8945-cf5a34458e6e')

    allow(Rails.logger).to receive(:warn)
    described_class.perform_async(solr_url)
    expect(Rails.logger).to have_received(:warn)
  end

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
