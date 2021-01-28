require 'rails_helper'
include FormattingConcern
RSpec.describe BarcodeController, type: :controller do
  describe "#scsb" do
    context "when given a valid barcode" do
      it "enriches a complex MARC with holdings and item info" do
        stub_alma_item_barcode(mms_id: "998574693506421", item_id: "23153444680006421", holding_id: "22153448500006421", barcode: "32101044947941")
        stub_alma_ids(ids: "998574693506421", status: 200, fixture: "998574693506421")
        stub_alma_holding(mms_id: "998574693506421", holding_id: "22153448500006421")

        voyager_comparison = MARC::XMLReader.new(File.open(Pathname.new(file_fixture_path).join("alma", "comparison", "voyager_scsb_32101044947941.xml"))).first
        get :scsb, params: { barcode: "32101044947941" }, format: :xml

        expect(response).to be_success
        record = MARC::XMLReader.new(StringIO.new(response.body)).first
        holding_id = "22153448500006421"
        expect(record["001"].value).to eq "998574693506421"
        expect(record["876"]["3"]).to eq voyager_comparison["876"]["3"] # Enum Chron
        # Ensure 852 fields come through
        expect(record["852"]["0"]).to eq holding_id
        expect(record["852"]["b"]).to eq "recap$pn"
        expect(record["852"]["c"]).to eq "pn"
        expect(record["852"]["t"]).to eq voyager_comparison["852"]["t"]
        expect(record["852"]["h"]).to eq voyager_comparison["852"]["h"]
        expect(record["852"]["i"]).to be_blank
        expect(record["852"]["x"]).to eq voyager_comparison["852"]["x"]
        # Ensure 866 fields come through
        expect(record["866"]["0"]).to eq holding_id
        expect(record["866"]["a"]).to eq voyager_comparison["866"]["a"]
        expect(record.fields("866").size).to eq voyager_comparison.fields("866").size
        # Ensure 867 fields come through
        expect(record["867"]).to eq voyager_comparison["867"]
        # Ensure 868 fields come through
        expect(record["868"]).to eq voyager_comparison["868"]
        # Ensure 856 is correct
        expect(record["856"].as_json).to eq voyager_comparison["856"].as_json
        # Ensure 959 is correct (empty)
        expect(record["959"]).to be_nil
      end
      it "enriches a bound-with item with multiple bibs it's attached to" do
        stub_alma_item_barcode(mms_id: "99121886293506421", item_id: "23269289930006421", holding_id: "22269289940006421", barcode: "32101066958685")
        stub_alma_ids(ids: "99121886293506421", status: 200, fixture: "99121886293506421")
        stub_alma_holding(mms_id: "99121886293506421", holding_id: "22269289940006421")
        stub_alma_ids(ids: ["9929455783506421", "9929455793506421", "9929455773506421"], status: 200, fixture: "bound_with_linked_records")

        get :scsb, params: { barcode: "32101066958685" }, format: :xml

        expect(response).to be_success
        records = MARC::XMLReader.new(StringIO.new(response.body)).to_a
        expect(records.length).to eq 3
        expect(records.map { |x| x["001"].value }).to eq ["9929455773506421", "9929455783506421", "9929455793506421"]
        records.each do |record|
          expect(record["876"]["z"]).to eq "PA"
          expect(record["852"]["h"]).to eq "3488.93344.333"
        end
      end
      it "enriches the MARC record with holdings and item info" do
        stub_alma_item_barcode(mms_id: "9972625743506421", item_id: "2340957190006421", holding_id: "2240957220006421", barcode: "32101069559514")
        stub_alma_ids(ids: "9972625743506421", status: 200, fixture: "9972625743506421")
        stub_alma_holding(mms_id: "9972625743506421", holding_id: "2240957220006421")

        voyager_comparison = MARC::XMLReader.new(File.open(Pathname.new(file_fixture_path).join("alma", "comparison", "voyager_scsb_32101069559514.xml"))).first
        get :scsb, params: { barcode: "32101069559514" }, format: :xml

        expect(response).to be_success
        record = MARC::XMLReader.new(StringIO.new(response.body)).first
        expect(record["001"].value).to eq "9972625743506421"
        expect(record["876"]["0"]).to eq "2240957220006421" # Holding ID
        expect(record["876"]["3"]).to eq voyager_comparison["876"]["3"] # enum_cron
        expect(record["876"]["a"]).to eq "2340957190006421" # Item ID
        expect(record["876"]["p"]).to eq "32101069559514" # Barcode
        expect(record["876"]["t"]).to eq voyager_comparison["876"]["t"] # Copy Number
        expect(record["876"]["j"]).to eq "Not Used"
        expect(record["876"]["h"]).to eq voyager_comparison["876"]["h"] # ReCAP Use Restriciton
        expect(record["876"]["x"]).to eq voyager_comparison["876"]["x"] # ReCAP Group Designation
        expect(record["876"]["z"]).to eq voyager_comparison["876"]["z"] # ReCAP Customer Code
        expect(record["852"]["h"]).to eq voyager_comparison["852"]["h"]
        expect(record["852"]["i"]).to be_blank
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
