require 'rails_helper'

RSpec.describe Dump, type: :model do
  before(:all) { system 'rake db:seed' }
  after(:all) { DumpFileType.destroy_all }

  let(:partner_recap_dump_type) { DumpType.find_by(constant: 'PARTNER_RECAP') }
  let(:log_file_type) { DumpFileType.find_by(constant: 'LOG_FILE') }
  let(:recap_record_file_type) { DumpFileType.find_by(constant: 'RECAP_RECORDS') }
  let(:dump) { Dump.create(dump_type: partner_recap_dump_type) }
  let(:timestamp) { Dump.send(:incremental_update_timestamp, partner_recap_dump_type) }
  let(:scsb_update) { Scsb::PartnerUpdates.new(dump: dump, timestamp: timestamp) }
  describe '#process_partner_files' do
    let(:update_directory_path) { 'spec/fixtures/scsb_updates/tmp' }
    it 'partner delete ids get added to dump object' do
      allow_any_instance_of(Scsb::PartnerUpdates).to receive(:get_partner_updates)
      allow_any_instance_of(Scsb::PartnerUpdates).to receive(:process_partner_updates)
      allow_any_instance_of(Scsb::PartnerUpdates).to receive(:log_record_fixes)
      allow_any_instance_of(Scsb::PartnerUpdates).to receive(:get_partner_deletes)
      ENV['SCSB_PARTNER_UPDATE_DIRECTORY'] = update_directory_path
      FileUtils.cp('spec/fixtures/scsb_updates/deletes.zip', update_directory_path)
      scsb_update.process_partner_files
      expect(dump.delete_ids).to eq(['SCSB-4884608', 'SCSB-9062868', 'SCSB-9068022',
                                     'SCSB-9068024', 'SCSB-9068025', 'SCSB-9068026'])
    end
    it 'partner updates attach recap marcxml and log files' do
      allow_any_instance_of(Scsb::PartnerUpdates).to receive(:get_partner_updates)
      allow_any_instance_of(Scsb::PartnerUpdates).to receive(:get_partner_deletes)
      allow_any_instance_of(Scsb::PartnerUpdates).to receive(:process_partner_deletes)
      ENV['SCSB_PARTNER_UPDATE_DIRECTORY'] = update_directory_path
      FileUtils.cp('spec/fixtures/scsb_updates/updates.zip', update_directory_path)
      scsb_update.process_partner_files
      expect(dump.dump_files.where(dump_file_type: recap_record_file_type).length).to eq(2)
      expect(dump.dump_files.where(dump_file_type: log_file_type).length).to eq(1)
    end
  end
end
