require 'rails_helper'

RSpec.describe Scsb::PartnerUpdates, type: :model, indexing: true do
  include ActiveJob::TestHelper

  describe '.full' do
    include_context 'scsb_partner_updates_full'
    it 'maintains the same api' do
      # for detailed testing see partner_updates/full_spec.rb
      described_class.full(dump:)
    end
  end
  describe '.incremental' do
    include_context 'scsb_partner_updates_incremental'

    it 'maintains the same api' do
      # for detailed testing see partner_updates/incremental_spec.rb
      described_class.incremental(dump:, timestamp:)
    end
  end
end
