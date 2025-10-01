require 'spec_helper'
require_relative '../../marc_to_solr/lib/cache_map'

RSpec.describe CacheMap do
  let(:cache) { instance_double(ActiveSupport::Cache::Store) }
  let(:logger) { instance_double(Logger, info: nil, debug: nil, error: nil) }
  let(:cache_map) { described_class.new(cache:, host: 'example.com', logger:) }

  describe '#cache_page' do
    let(:valid_doc) do
      {
        'id' => 'doc_123',
        'type' => 'Scanned Resource',
        'attributes' => {
          'identifier_ssim' => {
            'attributes' => {
              'value' => 'ark:/88435/abc123'
            }
          },
          'source_metadata_identifier_ssim' => {
            'attributes' => {
              'value' => 'bib_456'
            }
          }
        }
      }
    end

    let(:excluded_doc) do
      {
        'id' => 'doc_456',
        'type' => 'Issue',
        'attributes' => {
          'identifier_ssim' => {
            'attributes' => {
              'value' => 'ark:/88435/def456'
            }
          }
        }
      }
    end

    let(:doc_without_ark) do
      {
        'id' => 'doc_789',
        'type' => 'Scanned Resource',
        'attributes' => {
          'source_metadata_identifier_ssim' => {
            'attributes' => {
              'value' => 'bib_789'
            }
          }
        }
      }
    end

    let(:page_data) do
      {
        'data' => [valid_doc, excluded_doc, doc_without_ark]
      }
    end

    context 'when processing valid documents' do
      before do
        allow(cache).to receive(:exist?).and_return(false)
        allow(cache).to receive(:write)
      end

      it 'processes valid documents and caches them' do
        cache_map.send(:cache_page, page_data)

        expect(cache).to have_received(:write).with(
          'ark__88435_abc123',
          {
            id: 'doc_123',
            source_metadata_identifier: 'bib_456',
            internal_resource: 'Scanned Resource'
          }
        )
      end

      it 'skips excluded document types' do
        cache_map.send(:cache_page, page_data)

        expect(cache).not_to have_received(:write).with(
          'ark___88435_def456',
          anything
        )
      end

      it 'skips documents without ARKs' do
        cache_map.send(:cache_page, page_data)

        expect(cache).to have_received(:write).once
      end

      it 'logs debug messages for cached documents' do
        cache_map.send(:cache_page, page_data)

        expect(logger).to have_received(:debug).with(
          'Cached mapping for ark:/88435/abc123 to bib_456'
        )
      end
    end

    context 'when cache already exists' do
      before do
        allow(cache).to receive(:exist?).and_return(true)
        allow(cache).to receive(:write)
      end

      it 'does not overwrite existing cache entries' do
        cache_map.send(:cache_page, page_data)

        expect(cache).not_to have_received(:write)
      end
    end
  end

  describe '#process_doc?' do
    it 'returns true for allowed document types' do
      doc = { 'type' => 'Scanned Resource' }
      expect(cache_map.send(:process_doc?, doc)).to be true
    end

    it 'returns false for excluded document types' do
      ['Issue', 'Ephemera Folder', 'Coin'].each do |type|
        doc = { 'type' => type }
        expect(cache_map.send(:process_doc?, doc)).to be false
      end
    end
  end

  describe '#seed!' do
    let(:valid_response) do
      {
        'meta' => {
          'pages' => {
            'last_page?' => true
          }
        },
        'data' => []
      }
    end

    before do
      allow(cache).to receive(:fetch).and_return(nil)
      allow(cache).to receive(:write)
      allow(cache_map).to receive(:query).and_return(valid_response)
      allow(cache_map).to receive(:cache_page)
    end

    it 'handles valid response with meta key' do
      cache_map.seed!

      expect(cache_map).to have_received(:cache_page).with(valid_response)
    end

    context 'when response is missing meta key' do
      before do
        allow(cache_map).to receive(:query).and_return({ 'data' => [] })
      end

      it 'logs error and returns' do
        cache_map.seed!

        expect(logger).to have_received(:error).with(/missing 'meta' key/)
        expect(cache_map).not_to have_received(:cache_page)
      end
    end
  end

  describe '#cache_document_mapping' do
    let(:doc) do
      {
        'id' => 'test_doc_123',
        'type' => 'Book'
      }
    end

    let(:ark) { 'ark:/88435/test789' }
    let(:bib_id) { 'bib_999' }

    context 'when cache entry does not exist' do
      before do
        allow(cache).to receive(:exist?).and_return(false)
        allow(cache).to receive(:write)
      end

      it 'writes to cache with correct data structure' do
        cache_map.send(:cache_document_mapping, doc, ark, bib_id)

        expect(cache).to have_received(:write).with(
          'ark__88435_test789',
          {
            id: 'test_doc_123',
            source_metadata_identifier: 'bib_999',
            internal_resource: 'Book'
          }
        )
      end
    end

    context 'when cache entry already exists' do
      before do
        allow(cache).to receive(:exist?).and_return(true)
        allow(cache).to receive(:write)
      end

      it 'does not write to cache' do
        cache_map.send(:cache_document_mapping, doc, ark, bib_id)

        expect(cache).not_to have_received(:write)
      end
    end
  end
end
