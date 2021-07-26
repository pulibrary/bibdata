# Abstraction responsible for calculating the status and status label of a given
# holding.
# @TODO Add support for all the statuses in
#   https://github.com/pulibrary/marc_liberation/issues/937
class AlmaAdapter::Status
  attr_reader :bib, :holding_item_data, :holding
  # @param bib [Alma::Bib]
  # @param holding_item_data [Alma::BibItem]
  # @param holding [Hash] Holding data pulled from Alma::AvailabilityResponse
  def initialize(bib:, holding_item_data:, holding:)
    @bib = bib
    @holding_item_data = holding_item_data
    @holding = holding
  end

  def to_s
    return "Some items not available" if holding["availability"] == "check_holdings"
    return holding["availability"].titlecase if holding["availability"]

    # For electronic holdings
    return holding["activation_status"].titlecase if holding["activation_status"]
  end
end
