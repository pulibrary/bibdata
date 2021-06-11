require 'rails_helper'

RSpec.describe IncrementalIndexJob, type: :job do
  subject(:index_job) { described_class.new }

  let(:dump1) { Dump.create }
  let(:indexer) { instance_double(Alma::Indexer) }
  let(:solr_url) { Rails.application.config.solr["url"] }

  before do
    allow(Alma::Indexer).to receive(:new).with(solr_url: solr_url).and_return(indexer)
    allow(indexer).to receive(:incremental_index!)
  end

  describe '.perform' do
    context 'with existing Dump objects' do
      let(:dump1) { Dump.create(index_status: Dump::STARTED) }
      let(:dump2) { Dump.create }

      it 'enqueues the new Dump object for a retry if an existing Dump objects is already being indexed' do
        dump1
        described_class.perform_now(dump2)

        expect(dump2).to be_enqueued
      end
    end

    context 'when an error occurs trying to index a Dump objects' do
      let(:dump1) { Dump.create }

      let(:indexer) { instance_double(Alma::Indexer) }
      let(:solr_url) { Rails.application.config.solr["url"] }
      let(:logger) { instance_double(ActiveSupport::Logger) }

      before do
        dump1

        allow(logger).to receive(:error)
        allow(Rails).to receive(:logger).and_return(logger)
        allow(Alma::Indexer).to receive(:new).with(solr_url: solr_url).and_return(indexer)
        allow(indexer).to receive(:incremental_index!).and_raise(StandardError)
      end

      it 'sets the index status for the Dump object as incomplete' do
        expect { described_class.perform_now(dump1) }.to raise_error(StandardError)
        expect(dump1).to be_started
        expect(logger).to have_received(:error).with("Failed to incrementally index Dump #{dump1.id}: indexer_error")
      end
    end

    it 'sends the dump to the Alma Indexer' do
      described_class.perform_now(dump1)

      expect(indexer).to have_received(:incremental_index!).with(dump1)
      expect(dump1).to be_done
    end
  end
end
