require 'rails_helper'

RSpec.describe Import::Partner::Full do
  include_context 'scsb_partner_updates_full'
  around do |example|
    Sidekiq::Testing.inline! do
      example.run
    end
  end

  it 'creates an event' do
    allow(Scsb::PartnerUpdates).to receive(:full)

    expect { described_class.perform_async }.to change(Event, :count).by(1)
    event = Event.last

    expect(event.start).not_to be_nil
    expect(event.finish).not_to be_nil
    expect(event.dump).to be_a(Dump)
    expect(event.dump.dump_type).to eq('partner_recap_full')
    expect(Scsb::PartnerUpdates).to have_received(:full)
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

    it 'can be run in a batch' do
      allow(FileUtils).to receive(:rm) # Don't delete the files for this test
      test_batch = Sidekiq::Batch.new
      test_batch.jobs do
        described_class.perform_async
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
