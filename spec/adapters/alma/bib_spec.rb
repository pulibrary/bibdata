# frozen_string_literal: true
require "rails_helper"

RSpec.describe Alma::Bib do
  let(:bibs) { "991227850000541, 991227840000541, 991227830000541" }
  let(:one_bib) { "991227850000541" }
  let(:alma_record) { file_fixture("alma/#{one_bib}.xml").read }
  let(:alma_marc_record) { MARC::XMLReader.new(StringIO.new(alma_record)).first }
  let(:alma_records) { file_fixture("alma/alma_three_records.xml").read }
  let(:records) { [] }
  let(:alma_marc_records) { MARC::XMLReader.new(StringIO.new(alma_records)).select {|record| records << record} }

  describe "#get_alma_records" do
    context "if one bib is provided" do
      # before do
#         stub_request(:get, "#{Alma::Adapter.base_path}/bibs?apikey=TESTME&expand=p_avail%2Ce_avail%2Cd_avail%2Crequests&mms_id=#{one_bib}&view=full").
#           to_return(status: 200, body: file_fixture("#{one_bib}.xml"), headers: {
#                      'Accept'=>'application/xml',
#                      'Accept-Encoding'=>'gzip;q=1.0,deflate;q=0.6,identity;q=0.3'
#                      # 'apikey' => 'TESTME'
#                       })
#       end
      it "returns one record" do
        allow(described_class).to receive(:get_alma_records).with(ids: one_bib).and_return(alma_marc_record)
        expect(described_class.get_alma_records(ids: one_bib)['001'].value).to eq "991227850000541"
      end
    end
    context "if an array of bibs is provided" do
      it "returns multiple records" do
        allow(described_class).to receive(:get_alma_records).with(ids: bibs).and_return(alma_marc_records)
        expect(described_class.get_alma_records(ids: bibs)[0]['001'].value).to eq "991227830000541"
        expect(described_class.get_alma_records(ids: bibs)[1]['001'].value).to eq "991227840000541"
        expect(described_class.get_alma_records(ids: bibs)[2]['001'].value).to eq "991227850000541"
      end
    end
  end
  describe "#ids_remove_spaces" do
    it "removes the spaces from the ids" do
      expect(described_class.ids_remove_spaces(ids: bibs)).to eq "991227850000541,991227840000541,991227830000541"
    end
  end
  describe "#ids_build_array" do
    it "builds an array of ids" do
      expect(described_class.ids_build_array(ids: bibs)).to eq ["991227850000541", "991227840000541", "991227830000541"]
    end
  end
end