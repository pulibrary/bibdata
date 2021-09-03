# Abstraction responsible for calculating the status and status label of a given
# holding.
# @TODO Add support for all the statuses in
#   https://github.com/pulibrary/marc_liberation/issues/937
class AlmaAdapter::Status
  attr_reader :bib, :holding, :aeon
  # @param bib [Alma::Bib]
  # @param holding [Hash] Holding data pulled from Alma::AvailabilityResponse
  # @param aeon [Bool] Is Aeon location?
  def initialize(bib:, holding:, aeon: false)
    @bib = bib
    @holding = holding
    @aeon = aeon
  end

  def to_s
    return "On-site Access" if on_site_holding?
    return "Some items not available" if holding["availability"] == "check_holdings"
    return holding["availability"].titlecase if holding["availability"]

    # For electronic holdings
    return holding["activation_status"].titlecase if holding["activation_status"]
  end

  def on_site_holding?
    return true if aeon
    on_site_locations.include? "#{holding['library_code']}$#{holding['location_code']}"
  end

  # Holdings in these location are for on-site use only
  def on_site_locations
    ["lewis$map", "lewis$maplf", "lewis$maplref", "lewis$mapmc", "lewis$mapmcm"]
  end
end
