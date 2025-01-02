require 'rails_helper'

RSpec.describe DumpFileIndexJob, indexing: true do
  let(:dump) { FactoryBot.create(:incremental_dump) }
  let(:dump_file_id) { dump.dump_files.first.id }

  describe '#perform' do
    it 'raises an error when traject errors' do
      expect { described_class.new.perform(dump_file_id, 'http://localhost:8983/solr/badcollection') }.to raise_error
    end
  end

  it 'enqueues the job once' do
    expect { described_class.perform_async(dump_file_id, '') }.to change(described_class.jobs, :size).by(1)
  end
end
