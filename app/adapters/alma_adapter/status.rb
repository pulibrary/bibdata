class AlmaAdapter::Status
  attr_reader :bib, :holding_item_data, :holding
  def initialize(bib:, holding_item_data:, holding:)
    @bib = bib
    @holding_item_data = holding_item_data
    @holding = holding
  end

  def to_s
    return "On-Site" if holding["availability"] == "available"
  end
end
