require 'rails_helper'
RSpec.describe DownloadAndProcessFullJob, type: :job do
  include ActiveJob::TestHelper
  include_context 'scsb_partner_updates_full'

  it 'enqueues DownloadPartnerFilesJob' do
    expect do
      described_class.perform_now(inst: 'CUL', dump_id: dump.id, prefix: 'scsbfull_cul_')
    end.to have_enqueued_job(DownloadPartnerFilesJob).once
  end
end
