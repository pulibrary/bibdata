require 'rails_helper'

RSpec.describe Scsb::PartnerUpdates, type: :model do
  let(:partner_recap_dump_type) { DumpType.find_by(constant: 'PARTNER_RECAP') }
  let(:log_file_type) { DumpFileType.find_by(constant: 'LOG_FILE') }
  let(:dump) { Dump.create(dump_type: partner_recap_dump_type) }
  let(:timestamp) { Dump.send(:incremental_update_timestamp, partner_recap_dump_type) }
  let(:update_directory_path) { Rails.root.join("tmp", "specs", "update_directory") }
  let(:scsb_file_dir) { Rails.root.join("tmp", "specs", "data") }
  let(:bucket) { instance_double("Scsb::S3Bucket") }

  before do
    FileUtils.rm_rf(scsb_file_dir)
    FileUtils.mkdir_p(scsb_file_dir)

    FileUtils.rm_rf(update_directory_path)
    FileUtils.mkdir_p(update_directory_path)

    allow(ENV).to receive(:[]).and_call_original
    allow(ENV).to receive(:[]).with("SCSB_FILE_DIR").and_return(scsb_file_dir)
    allow(ENV).to receive(:[]).with('SCSB_PARTNER_UPDATE_DIRECTORY').and_return(update_directory_path)

    allow(bucket).to receive(:list_files)
    allow(Scsb::S3Bucket).to receive(:new).and_return(bucket)
  end

  describe '.full' do
    let(:dump) { FactoryBot.create(:empty_partner_full_dump) }
    let(:file_type) { DumpFileType.find_by(constant: 'RECAP_RECORDS_FULL') }

    context "when there are files" do
      before do
        FileUtils.cp('spec/fixtures/scsb_updates/CUL_20210429_192300.zip', update_directory_path)
        FileUtils.cp('spec/fixtures/scsb_updates/NYPL_20210430_015000.zip', update_directory_path)
        allow(bucket).to receive(:download_recent).with(hash_including(file_filter: /CUL.*\.zip/)).and_return(Rails.root.join(update_directory_path, 'CUL_20210429_192300.zip').to_s)
        allow(bucket).to receive(:download_recent).with(hash_including(file_filter: /NYPL.*\.zip/)).and_return(Rails.root.join(update_directory_path, 'NYPL_20210430_015000.zip').to_s)
      end

      it 'downloads, processes, and attaches the files' do
        Scsb::PartnerUpdates.full(dump: dump)

        # attaches marcxml and log files
        expect(dump.dump_files.where(dump_file_type: file_type).length).to eq(4)
        expect(dump.dump_files.where(dump_file_type: log_file_type).length).to eq(1)
        expect(dump.dump_files.map(&:path)).to contain_exactly(
          File.join(scsb_file_dir, "scsbfull_cul_20210429_192300_1.xml.gz"),
          File.join(scsb_file_dir, "scsbfull_cul_20210429_192300_2.xml.gz"),
          File.join(scsb_file_dir, "scsbfull_nypl_20210430_015000_1.xml.gz"),
          File.join(scsb_file_dir, "scsbfull_nypl_20210430_015000_2.xml.gz"),
          a_string_matching(/#{scsb_file_dir}\/fixes_\d{4}_\d{2}_\d{2}.json.gz/)
        )

        # cleans up
        expect(Dir.empty?(update_directory_path)).to be true
      end
    end

    context "when there are no cul files" do
      before do
        FileUtils.cp('spec/fixtures/scsb_updates/NYPL_20210430_015000.zip', update_directory_path)
        allow(bucket).to receive(:download_recent).with(hash_including(file_filter: /CUL.*\.zip/)).and_return(nil)
        allow(bucket).to receive(:download_recent).with(hash_including(file_filter: /NYPL.*\.zip/)).and_return(Rails.root.join(update_directory_path, 'NYPL_20210430_015000.zip').to_s)
      end

      it 'downloads, processes, and attaches the nypl files and adds an error message' do
        Scsb::PartnerUpdates.full(dump: dump)

        # attaches marcxml and log files
        expect(dump.dump_files.where(dump_file_type: file_type).length).to eq(2)
        expect(dump.dump_files.where(dump_file_type: log_file_type).length).to eq(1)
        expect(dump.dump_files.map(&:path)).to contain_exactly(
          File.join(scsb_file_dir, "scsbfull_nypl_20210430_015000_1.xml.gz"),
          File.join(scsb_file_dir, "scsbfull_nypl_20210430_015000_2.xml.gz"),
          a_string_matching(/#{scsb_file_dir}\/fixes_\d{4}_\d{2}_\d{2}.json.gz/)
        )
        expect(dump.event.error).to eq "No full dump files found matching CUL"

        # cleans up
        expect(Dir.empty?(update_directory_path)).to be true
      end
    end

    context "when there are no matching files at all" do
      before do
        allow(bucket).to receive(:download_recent).with(hash_including(file_filter: /CUL.*\.zip/)).and_return(nil)
        allow(bucket).to receive(:download_recent).with(hash_including(file_filter: /NYPL.*\.zip/)).and_return(nil)
      end

      it 'does not download anything, adds an error message' do
        Scsb::PartnerUpdates.full(dump: dump)

        expect(dump.dump_files.where(dump_file_type: file_type).length).to eq(0)
        expect(dump.event.error).to eq "No full dump files found matching NYPL; No full dump files found matching CUL"
      end
    end
  end

  describe '.incremental' do
    let(:file_type) { DumpFileType.find_by(constant: 'RECAP_RECORDS') }
    before do
      FileUtils.cp('spec/fixtures/scsb_updates/updates.zip', update_directory_path)
      FileUtils.cp('spec/fixtures/scsb_updates/deletes.zip', update_directory_path)
      allow(bucket).to receive(:download_files).and_return(
        [Rails.root.join(update_directory_path, 'updates.zip').to_s],
        [Rails.root.join(update_directory_path, 'deletes.zip').to_s]
      )
    end

    it 'downloads, processes, and attaches the files' do
      Scsb::PartnerUpdates.incremental(dump: dump, timestamp: timestamp)

      # attaches marcxml and log files
      expect(dump.dump_files.where(dump_file_type: file_type).length).to eq(2)
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
