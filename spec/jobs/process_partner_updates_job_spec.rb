require 'rails_helper'
RSpec.describe ProcessPartnerUpdatesJob, type: :job, indexing: true do
  let(:params) { { file_prefix: 'scsb_update_', file: 'a_file' }.stringify_keys }

  it 'accepts the expected parameters' do
    expect { described_class.perform_async(params) }.not_to raise_error
  end

  context 'with zipped files' do
    it 'tries to unzip the files' do
      Sidekiq::Testing.inline! do
        allow(Zip::File).to receive(:open).with('a_file')
        allow(File).to receive(:unlink)
        described_class.perform_async(params)
        expect(Zip::File).to have_received(:open).with('a_file')
      end
    end
  end

  it 'is idempotent' do
    pending('making the job idempotent')
    Sidekiq::Testing.inline! do
      expect do
        described_class.perform_async(params)
        described_class.perform_async(params)
      end.not_to raise_error
    end
  end
end
