require 'rails_helper'

RSpec.describe Import::Partner::Full do
  include_context 'scsb_partner_updates_full'
  around do |example|
    Sidekiq::Testing.inline! do
      example.run
    end
  end

  context 'performing in a batch' do
    around do |example|
      Sidekiq::Testing.server_middleware do |chain|
        chain.add Sidekiq::Batch::Server
      end
      example.run
      Sidekiq::Testing.server_middleware do |chain|
        chain.remove Sidekiq::Batch::Server
      end
    end

    before do
      allow(FileUtils).to receive(:rm) # Don't delete the files for this context
    end

    it 'can be run in a batch' do
      test_batch = Sidekiq::Batch.new
      test_batch.jobs do
        described_class.perform_async
      end
    end

    it 'creates an event' do
      stub_partner_update = Scsb::PartnerUpdates::Full.new(dump: event.dump, dump_file_type: :recap_records_full)
      allow(Scsb::PartnerUpdates::Full).to receive(:new).and_return(stub_partner_update)
      allow(stub_partner_update).to receive(:download_and_process_full).and_call_original
      allow(Dump).to receive(:generated_date).and_call_original

      expect { described_class.perform_async }.to change(Event, :count).by(1)
      event = Event.last

      expect(event.start).not_to be_nil
      expect(event.success).not_to be_nil
      expect(event.finish).not_to be_nil
      expect(event.dump).to be_a(Dump)
      expect(event.dump.dump_type).to eq('partner_recap_full')
      expect(stub_partner_update).to have_received(:download_and_process_full).exactly(3).times
      expect(Dump).to have_received(:generated_date)
    end

    it 'runs callbacks' do
      stub_callback = Import::Partner::FullCallbacks.new
      allow(Import::Partner::FullCallbacks).to receive(:new).and_return(stub_callback)
      allow(stub_callback).to receive(:overall_success)
      described_class.perform_async
      expect(stub_callback).to have_received(:overall_success)
      # with the callback caught, it should not have set the finish or success values
      event = Event.last
      expect(event.finish).to be_nil
      expect(event.success).to be_nil
    end

    context 'with files that include private records' do
      let(:cul_private_csv) { 'private_ExportDataDump_Full_CUL_20210429_192300.csv' }

      let(:fixture_files) { [nypl_zip, nypl_csv, hl_zip, hl_csv] }
      before do
        FileUtils.cp(Rails.root.join(fixture_paths, cul_private_csv), Rails.root.join(update_directory_path, cul_csv))
      end
      it 'does not process files that include private records' do
        described_class.perform_async

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
    context 'with files from only some partners' do
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
        stub_partner_update = Scsb::PartnerUpdates::Full.new(dump: event.dump, dump_file_type: :recap_records_full)
        allow(Scsb::PartnerUpdates::Full).to receive(:new).and_return(stub_partner_update)
        described_class.perform_async

        # attaches marcxml and csv files
        dump.reload
        expect(dump.dump_files.where(dump_file_type: :recap_records_full).length).to eq(2)
        expect(dump.dump_files.map(&:path)).to contain_exactly(
          File.join(scsb_file_dir, 'scsbfull_nypl_20210430_015000_1.xml.gz'),
          File.join(scsb_file_dir, 'scsbfull_nypl_20210430_015000_2.xml.gz'),
          File.join(scsb_file_dir, 'ExportDataDump_Full_NYPL_20210430_015000.csv.gz')
        )
        expect(dump.event.error).to eq 'No metadata files found matching CUL; No metadata files found matching HL'
        # cleans up
        expect(FileUtils).to have_received(:rm).exactly(2).times
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
        stub_partner_update = Scsb::PartnerUpdates::Full.new(dump: event.dump, dump_file_type: :recap_records_full)
        allow(Scsb::PartnerUpdates::Full).to receive(:new).and_return(stub_partner_update)
        described_class.perform_async
        dump.reload
        expect(dump.dump_files.where(dump_file_type: :recap_records_full).length).to eq(0)
        expect(dump.event.error).to eq 'No metadata files found matching NYPL; No metadata files found matching CUL; No metadata files found matching HL'
      end
    end
  end

  describe 'when there are stale files in the update directory path' do
    let(:update_directory_path) { Rails.root.join('tmp/specs/update_directory') }

    it 'removes stale files' do
      allow(FileUtils).to receive(:rm)
      expect { described_class.perform_async }.to change(Event, :count).by(1)
      expect(FileUtils).to have_received(:rm).with(Rails.root.join('tmp/specs/update_directory/CUL_20210429_192300.zip').to_s)
      expect(FileUtils).to have_received(:rm).with(Rails.root.join('tmp/specs/update_directory/NYPL_20210430_015000.zip').to_s)
      expect(FileUtils).to have_received(:rm).with(Rails.root.join('tmp/specs/update_directory/HL_20210716_063500.zip').to_s)
      expect(Dir.exist?(Rails.root.join('tmp/specs/update_directory'))).to be true
    end

    context 'when one file deletion fails' do
      before do
        allow(FileUtils).to receive(:rm)
        allow(FileUtils).to receive(:rm).with(Rails.root.join('tmp/specs/update_directory/NYPL_20210430_015000.zip').to_s).and_raise(Errno::ENOENT, 'No such file or directory @ apply2files')
      end

      it 'still deletes the other files that have not failed' do
        described_class.perform_async

        expect(FileUtils).to have_received(:rm).exactly(6).times
        expect(File.file?(Rails.root.join('tmp/specs/update_directory/CUL_20210429_192300.zip'))).to be false
        expect(File.file?(Rails.root.join('tmp/specs/update_directory/HL_20210716_063500.zip'))).to be false
        expect(File.file?(Rails.root.join('tmp/specs/update_directory/scsb_update_20240108_183400_1.xml'))).to be false
      end
    end
  end
end
