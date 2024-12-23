require 'rails_helper'

RSpec.describe Scsb::PartnerUpdates::Update, type: :model, indexing: true do
  let(:update) { described_class.new(dump:, dump_file_type: :recap_records_full, timestamp: DateTime.now.to_time) }
  let(:scsb_file_dir) { Rails.root.join("tmp", "specs", "data") }
  let(:filepath) { File.join(scsb_file_dir, 'CUL_20210429_192300.zip') }
  let(:dump) { Dump.create(dump_type: :partner_recap_full) }

  describe '#process' do
    let(:scsb_record_leaderd) { MARC::XMLReader.new(scsb_file, external_encoding: 'UTF-8').first }
    let(:scsb_file) { file_fixture("scsb/scsb_leaderd.xml").to_s }
    let(:timestamp) { Dump.send(:incremental_update_timestamp) }

    it 'processes a scsb record and changes leader d to c' do
      partner_updates = described_class.new(dump:, timestamp:, dump_file_type: :recap_records)
      expect(scsb_record_leaderd.leader[5]).to eq('d')
      processed_record = described_class.process_record(scsb_record_leaderd)
      expect(processed_record.leader[5]).to eq('c')
    end
  end
end
