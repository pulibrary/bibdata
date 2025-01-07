require 'rails_helper'

RSpec.describe Import::Partner::DownloadFullFileJob do
  include_context 'scsb_partner_updates_full'

  around do |example|
    Sidekiq::Testing.inline! do
      Sidekiq::Testing.server_middleware do |chain|
        chain.add Sidekiq::Batch::Server
      end
      example.run
      Sidekiq::Testing.server_middleware do |chain|
        chain.remove Sidekiq::Batch::Server
      end
    end
  end

  let(:stub_zip) { Zip::File.open('spec/fixtures/scsb_updates/NYPL_20210430_015000.zip') }
  let(:first_entry) { stub_zip.to_a[0] }
  let(:second_entry) { stub_zip.to_a[1] }

  before do
    allow(Zip::File).to receive(:open).and_yield(stub_zip)
    allow(stub_zip).to receive(:each).and_yield(first_entry).and_yield(second_entry)
    allow(first_entry).to receive(:extract).and_call_original
    allow(second_entry).to receive(:extract).and_call_original
  end

  it 'calls entry twice' do
    expect do
      testing_batch = Sidekiq::Batch.new
      testing_batch.jobs do
        described_class.perform_async(dump.id, 'NYPL', 'scsbfull_nypl_')
      end
    end.not_to raise_error(Zip::DestinationFileExistsError)
    expect(first_entry).to have_received(:extract)
    expect(second_entry).to have_received(:extract)
  end

  context 'with a pre-existing destination file' do
    before do
      FileUtils.touch('tmp/specs/update_directory/scsbfull_nypl_20210430_015000_1.xml')
    end

    it 'does not raise an error if the destination file exists' do
      expect do
        testing_batch = Sidekiq::Batch.new
        testing_batch.jobs do
          described_class.perform_async(dump.id, 'NYPL', 'scsbfull_nypl_')
        end
      end.not_to raise_error(Zip::DestinationFileExistsError)
      expect(first_entry).to have_received(:extract)
      expect(second_entry).to have_received(:extract)
    end
  end
end
