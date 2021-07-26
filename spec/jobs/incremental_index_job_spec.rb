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
      let(:dump1) { Dump.create(dump_files: [DumpFile.create(index_status: :started)]) }
      let(:dump2) { Dump.create }

      it 'enqueues the new Dump object for a retry if an existing Dump objects is already being indexed' do
        dump1
        described_class.perform_now(dump2)

        expect(dump2).to be_enqueued
      end
    end
    context 'with enqueued Dump objects' do
      let(:dump1) { Dump.create(dump_files: [DumpFile.create]) }
      let(:dump2) { Dump.create }

      it 'enqueues the new Dump object for a retry if an existing Dump objects is already being indexed' do
        described_class.perform_now(dump1)
        described_class.perform_now(dump2)

        expect(dump2).to be_enqueued
      end
    end

    it 'sends the dump to the Alma Indexer' do
      described_class.perform_now(dump1)

      expect(indexer).to have_received(:incremental_index!).with(dump1)
    end
  end
end
