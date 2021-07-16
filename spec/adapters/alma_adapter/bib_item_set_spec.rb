require 'rails_helper'

RSpec.describe AlmaAdapter::BibItemSet do
  it "behaves like an enumerable object" do
    items = [AlmaAdapter::AlmaItem.new("test")]
    bib_item_set = described_class.new(items: items, adapter: nil)
    expect(bib_item_set.all? { |s| s.recap_status == "Not Used" }).to be true
  end

  describe "#holding_summary" do
    let(:alma_item) do
      AlmaAdapter::AlmaItem.new(
        Alma::BibItem.new(
          "item_data" => {
            "pid" => "23201851070006421",
            "barcode" => "32101097382343",
            "library" => { "value" => "firestone", "desc" => "Firestone Library" },
            "location" => { "value" => "stacks", "desc" => "Firestone Library" },
            "policy" => {},
            "creation_date" => "2020-12-02Z"
          },
          "holding_data" => {
            "holding_id" => "22201851080006421",
            "call_number" => "HD6331 .H88 2018"
          }
        )
      )
    end

    it "formats the item list as a hash of locations / holdings / items data" do
      set = described_class.new(items: [alma_item], adapter: nil)
      holding = set.holding_summary["firestone$stacks"].first
      expect(holding.keys).to contain_exactly("holding_id", "call_number", "items")
      expect(holding["holding_id"]).to eq "22201851080006421"
      expect(holding["call_number"]).to eq "HD6331 .H88 2018"
      item = holding["items"].first
      expect(item.keys).to include("id", "pid", "perm_location", "temp_location", "creation_date")
    end

    it "filters to specific item keys if provided" do
      set = described_class.new(items: [alma_item], adapter: nil)
      summary = set.holding_summary(item_key_filter: ["perm_location"])
      item = summary["firestone$stacks"].first["items"].first
      expect(item.keys).to contain_exactly("perm_location")
    end
  end
end
