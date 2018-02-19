require 'rails_helper'

RSpec.describe ElectronicLocation, type: :model do
  subject(:electronic_location) do
    described_class.new(
      access_method: ElectronicLocations::Indicators::HTTP,
      relationship: ElectronicLocations::Relationships::VERSION,
      subfields: subfields,
      holdings: holdings,
      iiif_manifest_uris: iiif_manifest_uris)
  end
  let(:subfields) do
    [
      {
        ElectronicLocations::SubfieldCodes::LINK_TEXT => 'arks.princeton.edu',
        ElectronicLocations::SubfieldCodes::URI => 'http://arks.princeton.edu/ark:/88435/5m60qr98h'
      }
    ]
  end
  let(:holdings) do
    [
      ElectronicLocations::Holding.new(id: '4850352', value: 'http://localdomain/holding')
    ]
  end
  let(:iiif_manifest_uris) do
    [
      ElectronicLocations::IIIFManifestURI.new(ark: 'http://arks.princeton.edu/ark:/88435/5m60qr98h', value: 'https://figgy.princeton.edu/concern/scanned_resources/441d6471-9c97-4add-aa09-91c056e0fc0b/manifest')
    ]
  end

  describe '#identifier' do
    it 'retrieves ARKs for an electronic location record' do
      expect(electronic_location.identifier).to eq 'http://arks.princeton.edu/ark:/88435/5m60qr98h'
    end
  end
end
