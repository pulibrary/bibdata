require 'rails_helper'

RSpec.describe Dump, type: :model do
  before(:all) { system 'rake db:seed' }
  after(:all) { DumpFileType.destroy_all }

  let(:partner_recap_dump_type) { DumpType.find_by(constant: 'PARTNER_RECAP') }
  describe '#last_incremental_update' do
    let(:test_create_time) { '2017-04-29 20:10:29'.to_time }
    xit 'sets to yesterday when no partner recap object is there' do
      Dump.destroy_all
      timestamp = Scsb::PartnerUpdates.new(dump: dump).send(:set_timestamp).strftime("%Y%m%d")
      expect(timestamp).to eq((DateTime.current - 1).to_time.strftime("%Y%m%d"))
    end
    it 'sets to create time of previous partner recap dump when there' do
      Dump.create(dump_type: partner_recap_dump_type, created_at: test_create_time)
      timestamp = Dump.send(:last_incremental_update, partner_recap_dump_type)
      expect(timestamp).to eq(test_create_time)
    end
  end
end
