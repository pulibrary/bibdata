require 'rails_helper'

RSpec.describe ElectronicLocationsFactory, type: :service do
  let(:iiif_manifest_paths) do
    {
      'http://arks.princeton.edu/ark:/88435/5m60qr98h' => 'https://figgy.princeton.edu/concern/scanned_resources/441d6471-9c97-4add-aa09-91c056e0fc0b/manifest'
    }
  end
  let(:holdings) do
    {
      'test-id' => { 'http://localdomain/holding' => ['this is a holding link', 'this is a note about the holding resource'] }
    }
  end
  let(:links) do
    {
      'http://localdomain/resource' => ['this is a link', 'this is a note about the resource']
    }
  end
  let(:electronic_access_links) do
    {
      'http://localdomain/resource' => ['this is a link', 'this is a note about the resource'],
      'iiif_manifest_paths': iiif_manifest_paths,
      'holding_record_856s': holdings
    }
  end
  let(:document) do
    {
      'electronic_access_1display': [JSON.dump(electronic_access_links)],
    }.stringify_keys
  end

  describe '.parse_iiif_manifest_paths' do
    it 'extracts the IIIF manifest URLs' do
      manifests = described_class.parse_iiif_manifest_paths(iiif_manifest_paths)

      expect(manifests).not_to be_empty
      expect(manifests.first).to be_a ElectronicLocations::IIIFManifestURI
      expect(manifests.first.ark.to_s).to eq 'http://arks.princeton.edu/ark:/88435/5m60qr98h'
      expect(manifests.first.value).to be_a URI::Generic
      expect(manifests.first.value.to_s).to eq 'https://figgy.princeton.edu/concern/scanned_resources/441d6471-9c97-4add-aa09-91c056e0fc0b/manifest'
    end
  end

  describe '.parse_holdings' do
    it 'extracts the holding URLs' do
      manifests = described_class.parse_holdings(holdings)

      expect(manifests).not_to be_empty
      expect(manifests.first).to be_a ElectronicLocations::Holding
      expect(manifests.first.id).to eq 'test-id'
      expect(manifests.first.value).to be_a URI::Generic
      expect(manifests.first.value.to_s).to eq 'http://localdomain/holding'
    end
  end

  describe '.parse_subfields' do
    it 'extracts the electronic location URLs' do
      manifests = described_class.parse_subfields(holdings, links)

      expect(manifests).not_to be_empty
      expect(manifests.first).to be_a Hash
      expect(manifests.first[ElectronicLocations::SubfieldCodes::URI]).to eq 'http://localdomain/holding'
      expect(manifests.first[ElectronicLocations::SubfieldCodes::LINK_TEXT]).to eq 'this is a holding link'
      expect(manifests.first[ElectronicLocations::SubfieldCodes::PUBLIC_NOTE]).to eq 'this is a note about the holding resource'

      expect(manifests.last).to be_a Hash
      expect(manifests.last[ElectronicLocations::SubfieldCodes::URI]).to eq 'http://localdomain/resource'
      expect(manifests.last[ElectronicLocations::SubfieldCodes::LINK_TEXT]).to eq 'this is a link'
      expect(manifests.last[ElectronicLocations::SubfieldCodes::PUBLIC_NOTE]).to eq 'this is a note about the resource'
    end
  end

  describe '.build' do
    it 'constructs ElectronicLocation Objects' do
      locations = described_class.build(document)

      expect(locations).not_to be_empty
      expect(locations.first).to be_a ElectronicLocation
    end
  end
end
