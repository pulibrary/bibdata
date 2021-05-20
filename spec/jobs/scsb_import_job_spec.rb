require 'rails_helper'

RSpec.describe ScsbImportJob do
  it 'initiates the incremental partner update' do
    allow(Scsb::PartnerUpdates).to receive(:incremental)
    described_class.perform_now(FactoryBot.create(:empty_recap_incremental_dump).id, DateTime.now)
    expect(Scsb::PartnerUpdates).to have_received(:incremental)
  end
end
