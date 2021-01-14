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
    ['pa', 'gp', 'qk', 'pf'].each do |code|
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
end
