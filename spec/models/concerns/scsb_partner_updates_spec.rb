require 'rails_helper'

RSpec.describe Dump, type: :model do

  before(:all) { system 'rake db:seed' }
  after(:all) { DumpFileType.destroy_all }

  let(:partner_recap_dump_type) { DumpType.find_by(constant: 'PARTNER_RECAP') }
  let(:log_file_type) { DumpFileType.find_by(constant: 'LOG_FILE') }
  let(:recap_record_file_type) { DumpFileType.find_by(constant: 'RECAP_RECORDS') }
  describe '#set_timestamp' do
    let(:test_create_time) { ('2017-04-29 20:10:29').to_time }
    let(:dump) { double('dump') }
    it 'sets to yesterday when no partner recap object is there' do
      Dump.destroy_all
      timestamp = Scsb::PartnerUpdates.new(dump: dump).send(:set_timestamp).strftime("%Y%m%d")
      expect(timestamp).to eq((DateTime.now - 1).to_time.strftime("%Y%m%d"))
    end
    it 'sets to create time of previous partner recap dump when there' do
      previous_dump = Dump.create(dump_type: partner_recap_dump_type, created_at: test_create_time)
      new_dump = Dump.create(dump_type: partner_recap_dump_type)
      timestamp = Scsb::PartnerUpdates.new(dump: dump).send(:set_timestamp)
      expect(timestamp).to eq(test_create_time)
    end
  end
  describe '#process_partner_files' do
    let(:update_directory_path) { 'spec/fixtures/scsb_updates/tmp' }
    it 'partner delete ids get added to dump object' do
      allow_any_instance_of(Scsb::PartnerUpdates).to receive(:get_partner_updates)
      allow_any_instance_of(Scsb::PartnerUpdates).to receive(:process_partner_updates)
      allow_any_instance_of(Scsb::PartnerUpdates).to receive(:log_record_fixes)
      allow_any_instance_of(Scsb::PartnerUpdates).to receive(:get_partner_deletes)
      ENV['SCSB_PARTNER_UPDATE_DIRECTORY'] = update_directory_path
      dump = Dump.create(dump_type: partner_recap_dump_type)
      scsb_update = Scsb::PartnerUpdates.new(dump: dump)
      FileUtils.cp('spec/fixtures/scsb_updates/deletes.zip', update_directory_path)
      scsb_update.process_partner_files
      expect(dump.delete_ids).to eq(['SCSB-4884608','SCSB-9062868','SCSB-9068022',
                                     'SCSB-9068024','SCSB-9068025','SCSB-9068026'])
    end
    it 'partner updates attach recap marcxml and log files' do
      allow_any_instance_of(Scsb::PartnerUpdates).to receive(:get_partner_updates)
      allow_any_instance_of(Scsb::PartnerUpdates).to receive(:get_partner_deletes)
      allow_any_instance_of(Scsb::PartnerUpdates).to receive(:process_partner_deletes)
      ENV['SCSB_PARTNER_UPDATE_DIRECTORY'] = update_directory_path
      dump = Dump.create(dump_type: partner_recap_dump_type)
      scsb_update = Scsb::PartnerUpdates.new(dump: dump)
      FileUtils.cp('spec/fixtures/scsb_updates/updates.zip', update_directory_path)
      scsb_update.process_partner_files
      expect(dump.dump_files.where(dump_file_type: recap_record_file_type).length).to eq(2)
      expect(dump.dump_files.where(dump_file_type: log_file_type).length).to eq(1)
    end
  end
end
