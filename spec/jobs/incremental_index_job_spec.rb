require 'rails_helper'

RSpec.describe IncrementalIndexJob, type: :job do
  subject(:index_job) { described_class.new }

  describe '.perform' do
    it 'sends the dump to the Alma Indexer' do
      dump = Dump.new

      indexer = instance_double(Alma::Indexer)
      solr_url = Rails.application.config.solr["url"]
      allow(Alma::Indexer).to receive(:new).with(solr_url: solr_url).and_return(indexer)
      allow(indexer).to receive(:incremental_index!)

      described_class.perform_now(dump)

      expect(indexer).to have_received(:incremental_index!).with(dump)
    end
  end
end
