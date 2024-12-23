require 'rails_helper'

RSpec.describe Scsb::PartnerUpdates::Full, type: :model, indexing: true do
  include ActiveJob::TestHelper
  include_context 'scsb_partner_updates_full'

  it 'can be instantiated' do
    described_class.new(dump:, dump_file_type: :something)
  end

  context 'with files' do
    context 'from all partners' do
      context 'that are public' do
        let(:fixture_files) { [cul_csv] }

        it 'determines that the file is valid' do
          expect(described_class.validate_csv(inst: "CUL", dump_id: dump.id)).to be true
        end
      end
      context 'that are private' do
        let(:cul_private_csv) { 'private_ExportDataDump_Full_CUL_20210429_192300.csv' }

        let(:fixture_files) { [nypl_zip, nypl_csv, hl_zip, hl_csv] }
        before do
          FileUtils.cp(Rails.root.join(fixture_paths, cul_private_csv), Rails.root.join(update_directory_path, cul_csv))
        end
        it 'determines that the file is not valid' do
          expect(described_class.validate_csv(inst: "CUL", dump_id: dump.id)).to be false
        end
        it 'adds errors to the dump' do
          partner_full_update.process_full_files
          perform_enqueued_jobs
          perform_enqueued_jobs
          perform_enqueued_jobs
          dump.reload
          expect(dump.event.error).to include("Metadata file indicates that dump for CUL does not include the correct Group IDs, not processing. Group ids: 1*2*3*5*6")
        end
        it 'does not process files that include private records' do
          partner_full_update.process_full_files
          perform_enqueued_jobs
          perform_enqueued_jobs
          perform_enqueued_jobs
          expect(s3_bucket).to have_received(:download_recent).with(hash_including(file_filter: /CUL.*\.csv/))
          # Does not download records associated with metadata with private records
          expect(s3_bucket).not_to have_received(:download_recent).with(hash_including(file_filter: /CUL.*\.zip/))
          # Still downloads and processes records not associated with private records
          expect(s3_bucket).to have_received(:download_recent).with(hash_including(file_filter: /NYPL.*\.zip/))
          expect(s3_bucket).to have_received(:download_recent).with(hash_including(file_filter: /HL.*\.zip/))
          # cleans up
          expect(Dir.empty?(update_directory_path)).to be true
        end
      end
    end

    context 'from only some partners' do
      let(:fixture_files) { [nypl_zip, nypl_csv] }
      let(:filter_response_pairs) do
        [
          [/CUL.*\.zip/, nil],
          [/CUL.*\.csv/, nil],
          [/HL.*\.zip/, nil],
          [/HL.*\.csv/, nil],
          [/NYPL.*\.zip/, Rails.root.join(update_directory_path, nypl_zip).to_s],
          [/NYPL.*\.csv/, Rails.root.join(update_directory_path, nypl_csv).to_s]
        ]
      end

      it 'downloads, processes, and attaches the nypl files and adds an error message' do
        partner_full_update.process_full_files
        perform_enqueued_jobs
        perform_enqueued_jobs
        perform_enqueued_jobs
        dump.reload
        # attaches marcxml and log files
        expect(dump.dump_files.where(dump_file_type: :recap_records_full).length).to eq(2)
        expect(dump.dump_files.where(dump_file_type: :log_file).length).to eq(1)
        expect(dump.dump_files.map(&:path)).to contain_exactly(
          File.join(scsb_file_dir, "scsbfull_nypl_20210430_015000_1.xml.gz"),
          File.join(scsb_file_dir, "scsbfull_nypl_20210430_015000_2.xml.gz"),
          File.join(scsb_file_dir, "ExportDataDump_Full_NYPL_20210430_015000.csv.gz"),
          a_string_matching(/#{scsb_file_dir}\/fixes_\d{4}_\d{2}_\d{2}.json.gz/)
        )
        expect(dump.event.error).to eq "No metadata files found matching CUL; No metadata files found matching HL"

        # cleans up
        expect(Dir.empty?(update_directory_path)).to be true
      end
    end
  end

  context 'when there are no matching files at all' do
    let(:dump) { FactoryBot.create(:empty_partner_full_dump) }
    let(:filter_response_pairs) do
      [
        [/CUL.*\.zip/, nil],
        [/CUL.*\.csv/, nil],
        [/NYPL.*\.zip/, nil],
        [/NYPL.*\.csv/, nil],
        [/HL.*\.zip/, nil],
        [/HL.*\.csv/, nil]
      ]
    end

    it 'does not download anything, adds an error message' do
      partner_full_update.process_full_files
      perform_enqueued_jobs
      perform_enqueued_jobs
      perform_enqueued_jobs
      dump.reload
      expect(dump.dump_files.where(dump_file_type: :recap_records_full).length).to eq(0)
      expect(dump.event.error).to eq "No metadata files found matching NYPL; No metadata files found matching CUL; No metadata files found matching HL"
    end
  end
end
