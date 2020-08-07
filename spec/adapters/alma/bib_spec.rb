# frozen_string_literal: true
require "rails_helper"

RSpec.describe Alma::Bib do
  let(:bibs) { "991227850000541, 991227840000541, 991227830000541" }
  let(:one_bib) { "991227850000541" }
  let(:alma_record) { file_fixture("alma/#{one_bib}.xml").read }
  let(:alma_marc_record) { MARC::XMLReader.new(StringIO.new(alma_record)).first }
  let(:holdings_991227840000541) { file_fixture("alma/991227840000541_holdings.xml").read }
  # let(:holdings_record) { MARC::XMLReader.new(StringIO.new(holdings_991227840000541)).first }
  let(:records) { [] }
  let(:alma_records) { file_fixture("alma/alma_three_records.xml").read }
  let(:alma_marc_records) { MARC::XMLReader.new(StringIO.new(alma_records)).select {|record| records << record} }

  describe "#get_bib_record" do
    context "if one bib is provided" do
      it "returns one record" do
        allow(described_class).to receive(:get_bib_record).with(one_bib).and_return(alma_marc_record)
        expect(described_class.get_bib_record(one_bib)['001'].value).to eq "991227850000541"
      end
    end
    context "if an array of bibs is provided" do
      it "returns multiple records" do
        allow(described_class).to receive(:get_bib_record).with(bibs).and_return(alma_marc_records)
        expect(described_class.get_bib_record(bibs)[0]['001'].value).to eq "991227830000541"
        expect(described_class.get_bib_record(bibs)[1]['001'].value).to eq "991227840000541"
        expect(described_class.get_bib_record(bibs)[2]['001'].value).to eq "991227850000541"
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
  describe "records with no availability" do
    it "doesn't have an AVA tag" do
      # find an alma record with no 952 from the publishing job to add it as a fixture.
    end
  end
  describe "with an alma record that has an ARK" do
    it "exposes the ark" do
      # find an alma record with an ark.princeton.edu
    end
  end
  describe "alma record with no item" do
    # it has a holding
    # it doesn't have an item. This should be checked on the Alma::Holding
    it "has a holding" do
    end
  end
  describe "alma holding with order information" do
    # alma record with a po line.
    it "displays ..." do
    end
  end
  # no need to check for a 959 in Alma. This will be a check after the index
  describe "alma holding with order information" do
    it "has a PO line" do
      # we added a PO for a holding
      # MMS ID 99227515106421 Holdings ID 2284011070006421 Item ID 2384011050006421
      # it has in the AVA $e unavailable <subfield code="e">unavailable</subfield>
      # we might want to test this on the item level or in the availability.
      # when we first added the PO line it created the item 2384011050006421 with an on order status.
      # This is different from voyager where it doesn't add an item when the user creates a PO line.
      # What does the AVA tag display after the PO is accepted.
    end
  end
  describe '#get_holding_records' do
    it "returns the holdings for a bib" do
      allow(described_class).to receive(:get_holding_records).with(one_bib).and_return(holdings_991227840000541)
      expect(described_class.get_holding_records(one_bib)).to be_a(String)
    end
  end
end
