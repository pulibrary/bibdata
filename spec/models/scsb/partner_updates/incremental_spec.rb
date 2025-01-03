require 'rails_helper'

RSpec.describe Scsb::PartnerUpdates::Incremental, type: :model do
  include_context 'scsb_partner_updates_incremental'
  let(:partner_incremental_update) { described_class.new(dump:, dump_file_type: :recap_records, timestamp:) }

  it 'can be instantiated' do
    described_class.new(dump:, dump_file_type: :something, timestamp:)
  end

  describe 'incremental update' do
    it 'downloads, processes, and attaches the files' do
      partner_incremental_update.process_incremental_files

      # attaches marcxml and log files
      expect(dump.dump_files.where(dump_file_type: :recap_records).length).to eq(2)
      expect(dump.dump_files.map(&:path)).to contain_exactly(
        File.join(scsb_file_dir, 'scsb_update_20210622_183200_1.xml.gz'),
        File.join(scsb_file_dir, 'scsb_update_20210622_183200_2.xml.gz')
      )
      dump.reload
      expect(dump.generated_date).to eq DateTime.parse('2021-06-22')

      # Adds delete IDs
      expect(dump.delete_ids).to eq(['SCSB-4884608', 'SCSB-9062868', 'SCSB-9068022',
                                     'SCSB-9068024', 'SCSB-9068025', 'SCSB-9068026'])
      # cleans up
      expect(Dir.empty?(update_directory_path)).to be true
    end

    it 'creates a dump which can be processed by IndexFunctions' do
      partner_incremental_update.process_incremental_files
      Sidekiq::Testing.inline! do
        expect { IndexFunctions.process_scsb_dumps([dump], Rails.application.config.solr['url']) }.not_to raise_error
      end
    end
  end
end
