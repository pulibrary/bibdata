require 'rails_helper'

RSpec.describe ::DumpLogIdsService do
  describe '#process_dump' do
    it 'gets the right counts' do
      dump = FactoryBot.create(:incremental_dump)
      service = described_class.new
      service.process_dump(dump.id)
      dump = Dump.find(dump.id)
      expect(dump.delete_ids.count).to eq 14
      expect(dump.update_ids.count).to eq 7
    end

    it 'validates the dump type' do
      dump = FactoryBot.create(:partner_recap_daily_dump)
      service = described_class.new
      expect { service.process_dump(dump.id) }.to raise_error(StandardError)
    end
  end
end
