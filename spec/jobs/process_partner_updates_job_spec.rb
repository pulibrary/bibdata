require 'rails_helper'
RSpec.describe ProcessPartnerUpdatesJob, type: :job do
  it 'enqueues a job' do
    expect { described_class.perform_later }.to have_enqueued_job
  end

  it 'accepts the expected parameters' do
    expect { described_class.perform_later(files: ['a_file'], file_prefix: 'scsb_update_') }.not_to raise_error
  end

  context 'with zipped files' do
    it 'tries to unzip the files' do
      allow(Zip::File).to receive(:open).with('a_file')
      allow(File).to receive(:unlink)
      described_class.perform_now(files: ['a_file'], file_prefix: 'scsb_update_')
      expect(Zip::File).to have_received(:open).with('a_file')
    end
  end
end
