require 'rails_helper'
RSpec.describe DownloadAndProcessFullJob, type: :job, indexing: true do
  include_context 'scsb_partner_updates_full'

  it 'enqueues DownloadPartnerFilesJob' do
    Sidekiq::Testing.inline! do
      allow(DownloadPartnerFilesJob).to receive(:perform_async)
      params = { inst: 'CUL', dump_id: dump.id, prefix: 'scsbfull_cul_' }.stringify_keys
      described_class.perform_async(params)
      expect(DownloadPartnerFilesJob).to have_received(:perform_async)
    end
  end
end