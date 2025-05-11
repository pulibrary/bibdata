# frozen_string_literal: true

require 'rails_helper'

describe 'BibdataRs::Theses::Fetcher', :rust do
  let(:fetcher) { BibdataRs::Theses::Fetcher.new }
  let(:api_communities) { File.read(file_fixture('theses/communities.json')) }
  let(:api_collections) { File.read(file_fixture('theses/api_collections.json')) }
  let(:api_client_get) { File.read(file_fixture('theses/api_client_get.json')) }
  let(:cache) { Rails.root.join('spec/fixtures/files/theses/cache_output.json').to_s }

  before do
    stub_request(:get, 'https://dataspace-dev.princeton.edu/rest/communities/')
      .to_return(status: 200, body: api_communities, headers: {})

    stub_request(:get, 'https://dataspace-dev.princeton.edu/rest/communities/267/collections')
      .to_return(status: 200, body: api_collections, headers: {})

    stub_request(:get, 'https://dataspace-dev.princeton.edu/rest/collections/361/items?expand=metadata&limit=100&offset=0')
      .to_return(status: 200, body: api_client_get, headers: {})

    stub_request(:get, 'https://dataspace-dev.princeton.edu/rest/collections/361/items?expand=metadata&limit=100&offset=100')
      .to_return(status: 200, body: '[]', headers: {})

    stub_request(:get, 'https://dataspace-dev.princeton.edu/rest/collections/9999/items?expand=metadata&limit=100&offset=0')
      .to_return(status: 200, body: '', headers: {})
  end

  context 'cache theses as json' do
    around do |example|
      File.delete(cache) if File.exist?(cache)
      temp_filepath = ENV.fetch('FILEPATH', nil)
      ENV['FILEPATH'] = cache
      example.run
      ENV['FILEPATH'] = temp_filepath
      File.delete(cache) if File.exist?(cache)
    end

    it 'exports theses as json' do
      fetched = fetcher.cache_all_collections
      expect(fetched).to be_an(Array)
      expect(fetched.length).to eq(1)
      document = fetched.first
      expect(document).to include('id' => 'dsp0141687h67f')
      expect(document).to include('title_display' => 'Calibration of the Princeton University Subsonic Instructional Wind Tunnel')
    end

    it 'knows where to write cached files' do
      expect(BibdataRs::Theses.theses_cache_path).to eq cache
    end

    it 'writes all collections to a cache file' do
      expect(File.exist?(cache)).to be false
      BibdataRs::Theses::Fetcher.write_all_collections_to_cache
      expect(File.exist?(cache)).to be true
      cache_export = JSON.parse(File.read(cache))
      expect(cache_export.first['id']).to eq 'dsp0141687h67f'
    end
  end

  context 'blank responses from DSpace API' do
    let(:log) { StringIO.new }
    let(:test_logger) do
      logger = Logger.new(log)
      logger.level = Logger::DEBUG
      logger
    end

    ##
    # When DSpace returns an empty string, retry the query RETRY_LIMIT times
    # If the issue is never resolved, the exception is raised.
    it 'retries if DSpace returns an empty string' do
      fetcher.logger = test_logger
      expect { fetcher.fetch_collection('9999') }.to raise_error JSON::ParserError
      log.rewind
      expect(log.read).to match("#{Orangetheses::RETRY_LIMIT} tries")
    end
  end
end
