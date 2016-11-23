require 'rails_helper'
include FormattingConcern
RSpec.describe BarcodeController, :type => :controller do
  describe '#valid_barcode' do
    context 'barcode is valid' do
      let(:valid_barcode1) { '32101123456789' }
      let(:valid_barcode2) { 'PULTST12345' }
      it 'returns an exact match' do
        expect(described_class.valid_barcode(valid_barcode1)).to eq(0)
        expect(described_class.valid_barcode(valid_barcode2)).to eq(0)
      end
    end
    context 'barcode is correct length but not valid' do
      let(:invalid_barcode_proper_length) { '31101123456789' }
      it 'returns nil' do
        expect(described_class.valid_barcode(invalid_barcode_proper_length)).to be_nil
      end
    end
    context 'barcode is not proper length' do
      let(:invalid_barcode_improper_length) { '321011234567890' }
      it 'returns nil' do
        expect(described_class.valid_barcode(invalid_barcode_improper_length)).to be_nil
      end
    end
  end
end
        
