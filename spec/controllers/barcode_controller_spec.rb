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
      it "enriches the MARC record with holdings and item info" do
        stub_alma_item_barcode(mms_id: "9972625743506421", item_id: "2340957190006421", holding_id: "2240957220006421", barcode: "32101069559514")
        stub_alma_ids(ids: "9972625743506421", status: 200, fixture: "9972625743506421")

        voyager_comparison = MARC::XMLReader.new(File.open(Pathname.new(file_fixture_path).join("alma", "comparison", "voyager_scsb_32101069559514.xml"))).first
        get :scsb, params: { barcode: "32101069559514" }, format: :xml

        expect(response).to be_success
        record = MARC::XMLReader.new(StringIO.new(response.body)).first
        expect(record["001"].value).to eq "9972625743506421"
        expect(record["876"]["0"]).to eq "2240957220006421" # Holding ID
        # expect(record["876"]["3"]).to eq voyager_comparison["876"]["3"] # enum_cron TODO: Enable after we figure this out.
        expect(record["876"]["a"]).to eq "2340957190006421" # Item ID
        expect(record["876"]["p"]).to eq "32101069559514" # Barcode
        expect(record["876"]["t"]).to eq voyager_comparison["876"]["t"] # Copy Number
        # expect(record["876"]["j"]).to eq "Not Charged" # Status. TODO: Enable
        #   when we figure out statuses.
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
