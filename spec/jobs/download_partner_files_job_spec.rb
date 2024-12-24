require 'rails_helper'
RSpec.describe DownloadPartnerFilesJob, type: :job, indexing: true do
  include_context 'scsb_partner_updates_full'

  let(:params) { { file_filter: /CUL.*\.zip/.as_json, dump_id: dump.id, file_prefix: 'scsbfull_cul_' }.stringify_keys }

  it 'downloads from s3' do
    Sidekiq::Testing.inline! do
      described_class.perform_async(params)
      expect(s3_bucket).to have_received(:download_recent).with(hash_including('file_filter': /CUL.*\.zip/))
    end
  end

  it 'enqueues ProcessPartnerUpdatesJob' do
    Sidekiq::Testing.inline! do
      allow(ProcessPartnerUpdatesJob).to receive(:perform_async).and_call_original
      described_class.perform_async(params)
      expect(ProcessPartnerUpdatesJob).to have_received(:perform_async).once
    end
  end
end
