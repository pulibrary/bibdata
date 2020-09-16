require 'rails_helper'

RSpec.describe Dump, type: :model do
  before(:all) { system 'rake db:seed' }
  after(:all) { DumpFileType.destroy_all }

  let(:partner_recap) { 'PARTNER_RECAP' }
  let(:partner_recap_dump_type) { DumpType.find_by(constant: partner_recap) }
  let(:test_create_time) { '2017-04-29 20:10:29'.to_time }
  describe '#last_incremental_update' do
    it 'returns nil when no dump object is there' do
      Dump.destroy_all
      timestamp = Dump.send(:last_incremental_update, partner_recap)
      expect(timestamp).to be_nil
    end
    it 'sets to create time of previous partner recap dump when there' do
      Dump.create(dump_type: partner_recap_dump_type, created_at: test_create_time)
      timestamp = Dump.send(:last_incremental_update, partner_recap)
      expect(timestamp).to eq(test_create_time)
    end
  end
  describe '#incremental_update_timestamp' do
    it 'returns yesterday when no environment variable or dump object is there' do
      ENV['TIMESTAMP'] = nil
      Dump.destroy_all
      timestamp = Dump.send(:incremental_update_timestamp, partner_recap).to_time.strftime("%Y%m%d")
      expect(timestamp).to eq((DateTime.now - 1).to_time.strftime("%Y%m%d"))
    end
    it 'sets to create time of previous partner recap dump when there' do
      Dump.create(dump_type: partner_recap_dump_type, created_at: test_create_time)
      timestamp = Dump.send(:incremental_update_timestamp, partner_recap)
      expect(timestamp).to eq(test_create_time.strftime('%Y-%m-%d %H:%M:%S.%6N %z'))
    end
    it 'sets to environment variable when there' do
      ENV['TIMESTAMP'] = '2017-07-01'
      timestamp = Dump.send(:incremental_update_timestamp, partner_recap).to_time.strftime("%Y%m%d")
      expect(timestamp).to eq(ENV['TIMESTAMP'].to_time.strftime("%Y%m%d"))
    end
  end
end
