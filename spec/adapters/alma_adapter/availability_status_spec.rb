require 'rails_helper'

RSpec.describe AlmaAdapter::AvailabilityStatus do
  describe "#bib_availability_from_items" do
    before do
      stub_alma_holding_items(mms_id: bib_id, holding_id: "ALL", filename: "#{bib_id}_holding_items.json", query: "order_by=enum_a")
      stub_alma_library(library_code: "firestone", location_code: "res3hr")
      stub_alma_library(library_code: "firestone", location_code: "stacks")
      stub_alma_library(library_code: "firestone", location_code: "dixn")
      stub_alma_library(library_code: "marquand", location_code: "res")
      stub_alma_library(library_code: "rare", location_code: "hsvm")
    end

    let(:bib) { Alma::Bib.new("mms_id" => bib_id) }
    let(:status) { described_class.new(bib: bib, deep_check: true) }
    let(:availability) { status.bib_availability_from_items }
    let(:status_label) { availability[holding_id][:status_label] }

    context 'when all items are available' do
      let(:bib_id) { '99125379706706421' }
      let(:holding_id) { '22897520080006421' }

      it "reports available" do
        expect(status_label).to eq "Available"
      end
    end

    context 'when all items are unavailable' do
      let(:bib_id) { '99125378873406421' }
      let(:holding_id) { '22897164770006421' }

      it "reports unavailable" do
        expect(status_label).to eq "Not Available"
      end
    end

    context 'when there is a mix of statuses' do
      let(:bib_id) { '99125379706706421' }
      let(:holding_id) { '22897390520006421' }

      it "reports some items not available" do
        expect(status_label).to eq "Some items not available"
      end
    end

    context 'when an Aeon item is missing' do
      let(:bib_id) { '9963575053506421' }
      let(:holding_id) { '22726823980006421' }

      it 'reports unavailable' do
        expect(status_label).to eq "Not Available"
      end
    end
  end
end
