require 'rails_helper'

RSpec.describe PartnerFull::PrepareWorkflowJob, type: :model do
  around do |example|
    Sidekiq::Testing.inline! do
      example.run
    end
  end

  it 'creates a new event and sets a start time' do
    expect { described_class.perform_async }.to change(Event, :count)
    event = Event.last
    expect(event.start).not_to be_nil
    expect(event.dump.dump_type).to eq('partner_recap_full')
  end

  it 'creates a new dump' do
    expect { described_class.perform_async }.to change(Dump, :count)
  end

  it 'creates a sidekiq batch' do
    allow(Sidekiq::Batch).to receive(:new).and_call_original
    described_class.perform_async
    # The number of times it receives this will grow as the job becomes more complex
    expect(Sidekiq::Batch).to have_received(:new).exactly(3).times
  end

  context 'with running the batch' do
    around do |example|
      Sidekiq::Testing.server_middleware do |chain|
        chain.add Sidekiq::Batch::Server
      end
      example.run
      Sidekiq::Testing.server_middleware do |chain|
        chain.remove Sidekiq::Batch::Server
      end
    end

    it 'has a callback' do
      stub_callback = PartnerFull::Callbacks.new
      allow(PartnerFull::Callbacks).to receive(:new).and_return(stub_callback)
      allow(stub_callback).to receive(:all_steps_done).and_call_original
      allow(stub_callback).to receive(:step1_done).and_call_original
      described_class.perform_async
      expect(stub_callback).to have_received(:all_steps_done).exactly(1).time
      expect(stub_callback).to have_received(:step1_done).exactly(1).time
    end

    it 'starts a job for each partner institution' do
      allow(PartnerFull::StartInstitutionJob).to receive(:perform_async)
      described_class.perform_async
      expect(PartnerFull::StartInstitutionJob).to have_received(:perform_async).exactly(3).times
    end

    it 'marks the event as finished' do
      described_class.perform_async
      event = Event.last
      expect(event.finish).not_to be_nil
      expect(event.success).to be_truthy
    end

    context 'cleaning up' do
      let(:update_directory_path) { Rails.root.join('tmp/specs/update_directory').to_s }

      before do
        allow(ENV).to receive(:fetch)
        allow(ENV).to receive(:fetch).with('SCSB_PARTNER_UPDATE_DIRECTORY', '/tmp/updates').and_return(update_directory_path)
        FileUtils.rm_rf(update_directory_path)
      end

      it 'prepares the update directory' do
        expect(Dir).not_to exist(update_directory_path)
        described_class.perform_async
        expect(Dir).to exist(update_directory_path)
      end

      it 'empties the update directory at completion' do
        described_class.perform_async
        expect(Dir).to be_empty(update_directory_path)
      end

      describe 'when there are stale files in the update directory path' do
        let(:update_directory_path) { Rails.root.join('tmp/specs/update_directory/') }

        before do
          FileUtils.mkdir_p(update_directory_path)
          allow(ENV).to receive(:fetch).and_call_original
          allow(ENV).to receive(:fetch).with('SCSB_PARTNER_UPDATE_DIRECTORY', '/tmp/updates').and_return(update_directory_path)
          FileUtils.cp('spec/fixtures/scsb_updates/CUL_20210429_192300.zip', update_directory_path)
          FileUtils.cp('spec/fixtures/scsb_updates/NYPL_20210430_015000.zip', update_directory_path)
          FileUtils.cp('spec/fixtures/scsb_updates/HL_20210716_063500.zip', update_directory_path)
          FileUtils.cp('spec/fixtures/scsb_updates/scsb_update_20240108_183400_1.xml', update_directory_path)
        end

        it 'removes stale files' do
          expect { described_class.perform_async }.to change(Event, :count).by(1)

          expect(File.file?(Rails.root.join('tmp/specs/update_directory/CUL_20210429_192300.zip'))).to be false
          expect(File.file?(Rails.root.join('tmp/specs/update_directory/NYPL_20210430_015000.zip'))).to be false
          expect(File.file?(Rails.root.join('tmp/specs/update_directory/HL_20210716_063500.zip'))).to be false
          expect(File.file?(Rails.root.join('tmp/specs/update_directory/scsb_update_20240108_183400_1.xml'))).to be false
          expect(Dir.exist?(Rails.root.join('tmp/specs/update_directory'))).to be true
        end

        context 'when one file deletion fails' do
          before do
            allow(FileUtils).to receive(:rm).and_call_original
            allow(FileUtils).to receive(:rm).with(Rails.root.join('tmp/specs/update_directory/NYPL_20210430_015000.zip').to_s).and_raise(Errno::ENOENT, 'No such file or directory @ apply2files')
          end

          it 'still deletes the other files that have not failed' do
            described_class.perform_async

            expect(FileUtils).to have_received(:rm).exactly(4).times
            expect(File.file?(Rails.root.join('tmp/specs/update_directory/CUL_20210429_192300.zip'))).to be false
            expect(File.file?(Rails.root.join('tmp/specs/update_directory/HL_20210716_063500.zip'))).to be false
            expect(File.file?(Rails.root.join('tmp/specs/update_directory/scsb_update_20240108_183400_1.xml'))).to be false
          end
        end
      end
    end
  end
end
