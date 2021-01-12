require 'rails_helper'
include FormattingConcern
RSpec.describe BarcodeController, type: :controller do
  describe "#scsb" do
    context "when given a valid barcode" do
      it "returns a MARC record" do
        stub_alma_item_barcode(mms_id: "99223010406421", item_id: "2381872030006421", holding_id: "2281872070006421", barcode: "32101108168939")
        stub_alma_ids(ids: "99223010406421", status: 200, fixture: "99223010406421")

        get :scsb, params: { barcode: "32101108168939" }, format: :xml

        expect(response).to be_success
        record = MARC::XMLReader.new(StringIO.new(response.body)).first
        expect(record).to be_present
        expect(record["001"].value).to eq "99223010406421"
      end
    end
  end
  describe '#valid_barcode' do
    context 'barcode is valid' do
      let(:valid_barcode1) { '32101123456789' }
      let(:valid_barcode2) { 'PULTST12345' }
      it 'returns true' do
        expect(described_class.valid_barcode?(valid_barcode1)).to eq(true)
        expect(described_class.valid_barcode?(valid_barcode2)).to eq(true)
      end
    end
    context 'barcode is correct length but not valid' do
      let(:invalid_barcode_proper_length) { '31101123456789' }
      it 'returns false' do
        expect(described_class.valid_barcode?(invalid_barcode_proper_length)).to eq(false)
      end
    end
    context 'barcode is not proper length' do
      let(:invalid_barcode_improper_length) { '321011234567890' }
      it 'returns false' do
        expect(described_class.valid_barcode?(invalid_barcode_improper_length)).to eq(false)
      end
    end
  end
end
