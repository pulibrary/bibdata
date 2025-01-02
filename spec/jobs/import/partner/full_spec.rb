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
      allow(stub_partner_update).to receive(:process_full_files).and_call_original

      expect { described_class.perform_async }.to change(Event, :count).by(1)
      event = Event.last

      expect(event.start).not_to be_nil
      expect(event.success).not_to be_nil
      expect(event.finish).not_to be_nil
      expect(event.dump).to be_a(Dump)
      expect(event.dump.dump_type).to eq('partner_recap_full')
      expect(stub_partner_update).to have_received(:process_full_files)
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
