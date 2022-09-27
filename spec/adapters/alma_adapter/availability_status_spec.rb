require 'rails_helper'

RSpec.describe AlmaAdapter::AvailabilityStatus do
  describe "#bib_availability_from_items" do
    before do
      stub_alma_holding_items(mms_id: "99125379706706421", holding_id: "ALL", filename: "99125379706706421_holding_items.json", query: "order_by=enum_a")
      stub_alma_library(library_code: "firestone", location_code: "res3hr")
      stub_alma_library(library_code: "firestone", location_code: "stacks")
      stub_alma_library(library_code: "firestone", location_code: "dixn")
      stub_alma_holding_items(mms_id: "99125378873406421", holding_id: "ALL", filename: "99125378873406421_holding_items.json", query: "order_by=enum_a")
      stub_alma_library(library_code: "marquand", location_code: "res")
    end

    it "reports available when all items are available" do
      bib = Alma::Bib.new("mms_id" => "99125379706706421")
      status = described_class.new(bib:, deep_check: true)
      availability = status.bib_availability_from_items
      expect(availability["22897520080006421"][:status_label]).to eq "Available"
    end

    it "reports unavailable when all items are unavailable" do
      bib = Alma::Bib.new("mms_id" => "99125378873406421")
      status = described_class.new(bib:, deep_check: true)
      availability = status.bib_availability_from_items
      expect(availability["22897164770006421"][:status_label]).to eq "Not Available"
    end

    it "reports some items not available when there is a mix of statuses" do
      bib = Alma::Bib.new("mms_id" => "99125379706706421")
      status = described_class.new(bib:, deep_check: true)
      availability = status.bib_availability_from_items
      expect(availability["22897390520006421"][:status_label]).to eq "Some items not available"
    end
  end
end
