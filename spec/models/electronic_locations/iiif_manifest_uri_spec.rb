require 'rails_helper'

RSpec.describe ElectronicLocations::IIIFManifestURI, type: :model do
  subject(:holding) { described_class.new(ark: 'http://arks.princeton.edu/ark:/88435/5m60qr98h', value: 'https://figgy.princeton.edu/concern/scanned_resources/441d6471-9c97-4add-aa09-91c056e0fc0b/manifest') }
  describe '#ark' do
    it 'accesses the location value as an ARK' do
      expect(holding.ark).to be_a URI::ARK
      expect(holding.ark.to_s).to eq 'http://arks.princeton.edu:80/ark:/88435/5m60qr98h'
    end
  end

  describe '#value' do
    it 'accesses the location value as a URI' do
      expect(holding.value).to be_a URI::Generic
      expect(holding.value.to_s).to eq 'https://figgy.princeton.edu/concern/scanned_resources/441d6471-9c97-4add-aa09-91c056e0fc0b/manifest'
    end
  end
end
