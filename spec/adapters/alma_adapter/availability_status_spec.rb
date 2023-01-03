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

  describe "#holding_status" do
    before do
      FactoryBot.create(:aeon_location, code: 'rare$hsvm', label: 'Manuscripts')
      stub_alma_library(library_code: "rare", location_code: "hsvm")
      stub_alma_holding_items(mms_id: "9963575053506421", holding_id: "ALL", filename: "9963575053506421_holding_items.json", query: "order_by=enum_a")
    end
    it "reports a missing aeon item as unavailable" do
      bib = Alma::Bib.new("mms_id" => "9963575053506421")
      status = described_class.new(bib:, deep_check: true)
      holding = {
        "holding_id" => "22726823980006421",
        "institution" => "01PRI_INST",
        "library_code" => "rare",
        "location" => "Manuscripts",
        "call_number" => "Islamic Manuscripts, Garrett no. 337L",
        "availability" => "unavailable",
        "total_items" => "1",
        "non_available_items" => "1",
        "location_code" => "hsvm",
        "call_number_type" => "8",
        "priority" => "1",
        "library" => "Special Collections",
        "inventory_type" => "physical"
      }
      holding_status = status.holding_status(holding:)
      expect(holding_status[:status_label]).to eq("Unavailable")
    end
  end
end
