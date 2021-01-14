require 'rails_helper'

RSpec.describe AlmaAdapter::AlmaItem do
  describe "#group_designation" do
    ['pa', 'gp', 'qk', 'pf'].each do |code|
      context "when location is #{code}" do
        it "returns Shared" do
          item = described_class.new(
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
          )
          expect(item.group_designation).to eq "Shared"
        end
      end
    end
    ['jq', 'pe', 'pg', 'ph', 'pq', 'qb', 'ql', 'qv', 'qx'].each do |code|
      context "when location is #{code}" do
        it "returns Private" do
          item = described_class.new(
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
          )

          expect(item.recap_use_restriction).to eq "Supervised Use"
          expect(item.group_designation).to eq "Private"
        end
      end
    end
  end
end
