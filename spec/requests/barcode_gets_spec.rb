require 'rails_helper'
require 'marc'

RSpec.describe "Barcode Gets", type: :request do
  describe "GET /barcode/32101070300312" do
    it "returns a collection of bibliographic records" do
      stub_voyager_barcodes('32101070300312')
      get '/barcode/32101070300312'
      expect(response.status).to be(200)
    end
  end
  describe "GET /barcode/321010702214" do
    it "returns an error when the barcode is not a valid form" do
      allow(VoyagerHelpers::Liberator).to receive(:get_records_from_barcode).and_return([])
      get '/barcode/321010702214'
      expect(response.status).to be(404)
    end
  end
  describe "GET /barcode/" do
    it "returns an error when no barcode is supplied" do
      allow(VoyagerHelpers::Liberator).to receive(:get_records_from_barcode).and_return(nil)
      get '/barcode/'
      expect(response.status).to be(404)
    end
  end
end
def stub_voyager_barcodes(barcode)
  f=File.expand_path("../../fixtures/#{barcode}.mrx",__FILE__)
  allow(VoyagerHelpers::Liberator).to receive(:get_records_from_barcode).and_return MARC::XMLReader.new(f).to_a
end
