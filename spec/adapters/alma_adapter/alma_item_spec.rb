require 'rails_helper'

RSpec.describe AlmaAdapter::AlmaItem do
  describe "#recap_use_restriction" do
    context "when location is pj, pk, pl, pm, pn, or pt" do
      it "returns In Library Use" do
        ["pj", "pk", "pl", "pm", "pn", "pt"].each do |code|
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
        end
      end
    end
    context "when location is pb, ph, ps, pw, pz, xc, xg, xm, xn, xp, xr, xw, xx" do
      it "returns Supervised Use" do
        ["pb", "ph", "ps", "pw", "pz", "xc", "xg", "xm", "xn", "xp", "xr", "xw", "xx"].each do |code|
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
        end
      end
    end
  end
end
