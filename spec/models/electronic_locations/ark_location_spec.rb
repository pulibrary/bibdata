require 'rails_helper'

RSpec.describe ElectronicLocations::ARKLocation, type: :model do
  subject(:holding) { described_class.new(value: 'http://arks.princeton.edu/ark:/88435/5m60qr98h') }
  describe '#value' do
    it 'accesses the location value as an ARK' do
      expect(holding.value).to be_a URI::ARK
      expect(holding.value.to_s).to eq 'http://arks.princeton.edu:80/ark:/88435/5m60qr98h'
    end
  end
end
