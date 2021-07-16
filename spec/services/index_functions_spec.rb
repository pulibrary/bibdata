require 'rails_helper'

RSpec.describe IndexFunctions do
  describe '#delete_ids' do
    let(:dump) do
      { 'ids' =>
        { 'delete_ids' => ['134', '234'] } }
    end
    it 'reuturns an array of bib ids for deletion' do
      expect(described_class.delete_ids(dump)).to eq ['134', '234']
    end
  end

  describe '.logger' do
    it 'constructs a logger for STDOUT' do
      expect(described_class.logger).to be_a(Logger)
    end

    context 'when within a Rails environment' do
      let(:logger) { instance_double(Logger) }

      before do
        allow(Rails).to receive(:logger).and_return(logger)
      end

      after do
        allow(Rails).to receive(:logger).and_call_original
      end

      it 'delegates to the Rails logger' do
        expect(described_class.logger).to eq(logger)
      end
    end
  end

  describe '#rsolr_connection' do
    let(:solr) { described_class.rsolr_connection('http://example.com') }

    it 'responds to .commit' do
      expect(solr).to respond_to(:commit)
    end

    it 'responds to .delete_by_id' do
      expect(solr).to respond_to(:delete_by_id).with(1).argument
    end

    context 'when Solr is unvailable' do
      let(:logger) { described_class.logger }

      before do
        allow(logger).to receive(:error)
        allow(RSolr).to receive(:connect).and_raise(StandardError)
        described_class.rsolr_connection('invalid')
      end

      it 'logs an error' do
        expect(logger).to have_received(:error).with('Failed to connect to Solr: StandardError')
      end
    end
  end
end
