require 'rails_helper'

RSpec.describe ScsbImportFullJob do
  it 'creates an event' do
    allow(Scsb::PartnerUpdates).to receive(:full)

    expect { described_class.perform_now }.to change { Event.count }.by(1)
    event = Event.last

    expect(event.start).not_to be nil
    expect(event.finish).not_to be nil
    expect(event.dump).to be_a(Dump)
    expect(event.dump.dump_type).to eq("partner_recap_full")
    expect(Scsb::PartnerUpdates).to have_received(:full)
  end

  describe 'when there stale files in the update directory path' do
    let(:update_directory_path) { Rails.root.join("tmp", "specs", "update_directory") }

    before do
      FileUtils.mkdir_p(update_directory_path)
      allow(ENV).to receive(:[]).and_call_original
      allow(ENV).to receive(:[]).with('SCSB_PARTNER_UPDATE_DIRECTORY').and_return(update_directory_path)
      FileUtils.cp('spec/fixtures/scsb_updates/CUL_20210429_192300.zip', update_directory_path)
      FileUtils.cp('spec/fixtures/scsb_updates/NYPL_20210430_015000.zip', update_directory_path)
      FileUtils.cp('spec/fixtures/scsb_updates/HL_20210716_063500.zip', update_directory_path)
      FileUtils.cp('spec/fixtures/scsb_updates/scsb_update_20240108_183400_1.xml', update_directory_path)
    end

    it 'removes stale files' do
      expect { described_class.perform_now }.to change { Event.count }.by(1)

      expect(File.file?(Rails.root.join("tmp", "specs", "update_directory", 'CUL_20210429_192300.zip'))).to be false
      expect(File.file?(Rails.root.join("tmp", "specs", "update_directory", 'NYPL_20210430_015000.zip'))).to be false
      expect(File.file?(Rails.root.join("tmp", "specs", "update_directory", 'HL_20210716_063500.zip'))).to be false
      expect(File.file?(Rails.root.join("tmp", "specs", "update_directory", 'scsb_update_20240108_183400_1.xml'))).to be false
      expect(Dir.exist?(Rails.root.join("tmp", "specs", "update_directory"))).to be true
    end
  end
end
