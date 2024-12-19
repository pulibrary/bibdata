require 'rails_helper'
RSpec.describe DownloadPartnerFilesJob, type: :job do
  include ActiveJob::TestHelper
  include_context 'scsb_partner_updates_full'

  it 'downloads from s3' do
    described_class.perform_now(file_filter: /CUL.*\.zip/.as_json, dump_id: dump.id, file_prefix: 'scsbfull_cul_')
    expect(s3_bucket).to have_received(:download_recent).with(hash_including(file_filter: /CUL.*\.zip/))
  end

  it 'enqueues ProcessPartnerUpdatesJob' do
    expect do
      described_class.perform_now(file_filter: /CUL.*\.zip/.as_json, dump_id: dump.id, file_prefix: 'scsbfull_cul_')
    end.to have_enqueued_job(ProcessPartnerUpdatesJob).once
  end

  it 'can perform the ProcessPartnerUpdatesJob' do
    described_class.perform_now(file_filter: /CUL.*\.zip/.as_json, dump_id: dump.id, file_prefix: 'scsbfull_cul_')
    perform_enqueued_jobs
  end
end
