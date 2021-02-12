require 'rails_helper'

RSpec.describe AlmaAdapter::BibItemSet do
  it "behaves like an enumerable object" do
    items = [AlmaAdapter::AlmaItem.new("test")]
    bib_item_set = described_class.new(items: items, adapter: nil)
    expect(bib_item_set.all? { |s| s.recap_status == "Not Used" }).to be true
  end
end
