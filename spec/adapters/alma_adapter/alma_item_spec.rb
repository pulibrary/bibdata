require 'rails_helper'

RSpec.describe AlmaAdapter::AlmaItem do
  def build_item(code:)
    Alma::BibItem.new(
      "item_data" => {
        "library" => {
          "desc" => "ReCAP", "value" => "recap"
        },
        "location" => {
          "desc" => code,
          "value" => code
        }
      }
    )
  end

  describe "#recap_customer_code" do
    context "when location starts with x" do
      it "returns PG" do
        item = described_class.new(
          build_item(code: "xx")
        )

        expect(item.recap_customer_code).to eq "PG"
      end
    end
    context "when location doesn't start with X" do
      it "capitalizes the code" do
        item = described_class.new(
          build_item(code: "pa")
        )

        expect(item.recap_customer_code).to eq "PA"
      end
    end
  end

  describe "#group_designation" do
    ['pv', 'pa', 'gp', 'qk', 'pf'].each do |code|
      context "when location is #{code}" do
        it "returns Shared" do
          item = described_class.new(
            build_item(code: code)
          )
          expect(item.group_designation).to eq "Shared"
        end
      end
    end
    ['jq', 'pe', 'pg', 'ph', 'pq', 'qb', 'ql', 'qv', 'qx'].each do |code|
      context "when location is #{code}" do
        it "returns Private" do
          item = described_class.new(
            build_item(code: code)
          )

          expect(item.group_designation).to eq "Private"
        end
      end
    end
  end

  describe "#recap_use_restriction" do
    ["pj", "pk", "pl", "pm", "pn", "pt"].each do |code|
      context "when location is #{code}" do
        it "returns In Library Use" do
          item = described_class.new(
            build_item(code: code)
          )

          expect(item.recap_use_restriction).to eq "In Library Use"
          expect(item.group_designation).to eq "Private"
        end
      end
    end
    ["pv"].each do |code|
      context "when location is #{code}" do
        it "returns In Library Use" do
          item = described_class.new(
            build_item(code: code)
          )

          expect(item.recap_use_restriction).to eq "In Library Use"
          expect(item.group_designation).to eq "Shared"
        end
      end
    end
    ["pb", "ph", "ps", "pw", "pz", "xc", "xg", "xm", "xn", "xp", "xr", "xw", "xx"].each do |code|
      context "when location is #{code}" do
        it "returns Supervised Use" do
          item = described_class.new(
            build_item(code: code)
          )

          expect(item.recap_use_restriction).to eq "Supervised Use"
          expect(item.group_designation).to eq "Private"
        end
      end
    end
  end

  describe "#cdl?" do
    context "when there is no work order type" do
      it "flags false" do
        item = described_class.new(
          build_item(code: "pa")
        )

        expect(item.cdl?).to eq false
      end
    end

    context "when the work order type is CDL" do
      it "flags true" do
        item = described_class.new(
          Alma::BibItem.new(
            "item_data" => {
              "library" => {
                "desc" => "ReCAP", "value" => "recap"
              },
              "location" => {
                "desc" => "pa",
                "value" => "pa"
              },
              "work_order_type" => {
                "value" => "CDL",
                "desc" => "Controlled Digital Lending"
              }
            }
          )
        )

        expect(item.cdl?).to eq true
      end
    end
  end

  describe "status" do
    let(:item) { described_class.new(bib_item) }
    let(:status) { item.calculate_status }
    let(:base_status) { { "value" => "0", "desc" => "Item in place" } }

    describe 'work order' do
      let(:process_type) { { "value" => "WORK_ORDER_DEPARTMENT", "desc" => "In Process" } }

      let(:bib_item) do
        Alma::BibItem.new(
          "bib_data" => { "mms_id" => "99122455086806421" },
          "holding_data" => { "holding_id" => "22477860740006421" },
          "item_data" => {
            "pid" => "23477860730006421",
            "base_status" => base_status,
            "work_order_type" => work_order_type,
            "work_order_at" => work_order_at
          }
        )
      end

      context 'in acquisitions' do
        let(:work_order_type) { { "value" => "AcqWorkOrder", "desc" => "Acquisitions and Cataloging" } }
        let(:work_order_at) { { "value" => "AcqDepttechserv", "desc" => "Acquisitions and Cataloging" } }

        it "marks the items as 'Not Available'" do
          expect(status[:code]).to eq "Not Available"
        end
      end

      context 'in collection development' do
        let(:work_order_type) { { "value" => "CollDev", "desc" => "Collection Development Office" } }
        let(:work_order_at) { { "value" => "CollDev", "desc" => "Collection Development Office" } }

        it "marks the items as 'Not Available'" do
          expect(status[:code]).to eq "Not Available"
        end
      end

      context 'in holdings management' do
        let(:work_order_type) { { "value" => "HMT", "desc" => "Holdings Management" } }
        let(:work_order_at) { { "value" => "HMT", "desc" => "Holdings Management" } }

        it "marks the items as 'Not Available'" do
          expect(status[:code]).to eq "Not Available"
        end
      end
    end
    describe 'process type' do
      let(:bib_item) do
        Alma::BibItem.new(
          "bib_data" => { "mms_id" => "9939075533506421" },
          "holding_data" => { "holding_id" => "22194161030006421" },
          "item_data" => {
            "pid" => "23194161020006421",
            "base_status" => base_status,
            "process_type" => process_type
          }
        )
      end

      context 'acquisitions' do
        let(:process_type) { { "value" => "ACQ", "desc" => "Acquisition" } }

        it "marks the items as 'Not Available'" do
          expect(status[:code]).to eq "Not Available"
        end
      end
      context 'missing' do
        let(:process_type) { { "value" => "MISSING", "desc" => "Missing" } }

        it "marks the items as 'Not Available'" do
          expect(status[:code]).to eq "Not Available"
        end
      end
    end

    describe 'base status' do
      let(:bib_item) do
        Alma::BibItem.new(
          "bib_data" => { "mms_id" => "9939075533506421" },
          "holding_data" => { "holding_id" => "22194161030006421" },
          "item_data" => {
            "pid" => "23194161020006421",
            "base_status" => base_status
          }
        )
      end

      context 'in place' do
        let(:base_status) { { "value" => "1", "desc" => "Item in place" } }

        it "marks the items as 'Available'" do
          expect(status[:code]).to eq "Available"
        end
      end
      context 'not in place' do
        let(:base_status) { { "value" => "0", "desc" => "Item not in place" } }

        it "marks the items as 'Not Available'" do
          expect(status[:code]).to eq "Not Available"
        end
      end
    end
  end
end
