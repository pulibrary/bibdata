require 'rails_helper'

RSpec.describe Scsb::PartnerUpdates::Full, type: :model do
  include_context 'scsb_partner_updates_full'

  it 'can be instantiated' do
    described_class.new(dump:, dump_file_type: :something)
  end
end
