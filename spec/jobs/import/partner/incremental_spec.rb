require 'rails_helper'

RSpec.describe Import::Partner::Incremental do
  it 'initiates the incremental partner update' do
    Sidekiq::Testing.inline! do
      allow(Scsb::PartnerUpdates).to receive(:incremental)
      described_class.perform_async(create(:empty_partner_recap_incremental_dump).id, DateTime.now.to_s)
      expect(Scsb::PartnerUpdates).to have_received(:incremental)
    end
  end
end
