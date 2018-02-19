require 'rails_helper'

RSpec.describe ElectronicLocations::Holding, type: :model do
  subject(:holding) { described_class.new(id: 'test-id', value: 'http://localdomain/test') }
  describe '#id' do
    it 'accesses the holding ID' do
      expect(holding.id).to eq 'test-id'
    end
  end

  describe '#value' do
    it 'accesses the location value as a URI' do
      expect(holding.value).to be_a URI::Generic
      expect(holding.value.to_s).to eq 'http://localdomain/test'
    end
  end
end
