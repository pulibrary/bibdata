require 'rails_helper'

RSpec.describe Scsb::PartnerUpdates, type: :model do
  describe '.incremental' do
    include_context 'scsb_partner_updates_incremental'

    it 'maintains the same api' do
      # for detailed testing see partner_updates/incremental_spec.rb
      described_class.incremental(dump:, timestamp:)
    end
  end
end
