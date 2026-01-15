require 'rails_helper'

RSpec.describe MarcxmlCompressor do
  let(:sample_xml) do
    <<~XML
      <?xml version="1.0" encoding="UTF-8"?>
      <record xmlns="http://www.loc.gov/MARC21/slim">
        <leader>00000nam a2200000 a 4500</leader>
        <controlfield tag="001">123456789</controlfield>
        <datafield tag="245" ind1="0" ind2="0">
          <subfield code="a">A Title</subfield>
        </datafield>
      </record>
    XML
  end

  describe '.compress' do
    it 'compresses an XML string' do
      compressed = described_class.compress(sample_xml)
      expect(compressed).to be_a(String)
    end

    it 'returns nil for nil input' do
      expect(described_class.compress(nil)).to be_nil
    end

    it 'returns nil for empty string' do
      expect(described_class.compress('')).to be_nil
    end
  end

  describe '.decompress' do
    it 'decompresses a compressed XML string' do
      compressed = described_class.compress(sample_xml)
      decompressed = described_class.decompress(compressed)
      expect(decompressed).to eq(sample_xml)
    end

    it 'returns nil for nil input' do
      expect(described_class.decompress(nil)).to be_nil
    end

    it 'returns nil for empty string' do
      expect(described_class.decompress('')).to be_nil
    end
  end
end
