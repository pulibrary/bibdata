require 'rails_helper'

RSpec.describe Dump, type: :model do
  let(:partner_recap_dump_type) { DumpType.find_by(constant: 'PARTNER_RECAP') }
  let(:recap_record_file_type) { DumpFileType.find_by(constant: 'RECAP_RECORDS') }
  let(:log_file_type) { DumpFileType.find_by(constant: 'LOG_FILE') }
  let(:dump) { Dump.create(dump_type: partner_recap_dump_type) }
  let(:timestamp) { Dump.send(:incremental_update_timestamp, partner_recap_dump_type) }

  describe '#process_partner_files' do
    let(:update_directory_path) { Rails.root.join("tmp", "specs", "update_directory") }
    let(:scsb_file_dir) { Rails.root.join("tmp", "specs", "data") }
    let(:bucket) { instance_double("Scsb::S3Bucket") }
    let(:scsb_update) { Scsb::PartnerUpdates.new(dump: dump, timestamp: timestamp, s3_bucket: bucket) }

    before do
      FileUtils.rm_rf(scsb_file_dir)
      FileUtils.mkdir_p(scsb_file_dir)

      FileUtils.rm_rf(update_directory_path)
      FileUtils.mkdir_p(update_directory_path)
      FileUtils.cp('spec/fixtures/scsb_updates/updates.zip', update_directory_path)
      FileUtils.cp('spec/fixtures/scsb_updates/deletes.zip', update_directory_path)

      allow(ENV).to receive(:[]).and_call_original
      allow(ENV).to receive(:[]).with("SCSB_FILE_DIR").and_return(scsb_file_dir)
      allow(ENV).to receive(:[]).with('SCSB_PARTNER_UPDATE_DIRECTORY').and_return(update_directory_path)

      allow(bucket).to receive(:list_files)
      allow(bucket).to receive(:download_files).and_return(
        [Rails.root.join(update_directory_path, 'updates.zip').to_s],
        [Rails.root.join(update_directory_path, 'deletes.zip').to_s]
      )
    end

    it 'downloads, processes, and attaches the files' do
      scsb_update.process_partner_files

      # attaches marcxml and log files
      expect(dump.dump_files.where(dump_file_type: recap_record_file_type).length).to eq(2)
      expect(dump.dump_files.where(dump_file_type: log_file_type).length).to eq(1)
      expect(dump.dump_files.map(&:path)).to contain_exactly(
        File.join(scsb_file_dir, "scsbupdateupdates_1.xml.gz"),
        File.join(scsb_file_dir, "scsbupdateupdates_2.xml.gz"),
        a_string_matching(/#{scsb_file_dir}\/fixes_\d{4}_\d{2}_\d{2}.json.gz/)
      )

      # Adds delete IDs
      expect(dump.delete_ids).to eq(['SCSB-4884608', 'SCSB-9062868', 'SCSB-9068022',
                                     'SCSB-9068024', 'SCSB-9068025', 'SCSB-9068026'])
      # cleans up
      expect(Dir.empty?(update_directory_path)).to be true
    end
  end
end
