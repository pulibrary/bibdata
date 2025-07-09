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
    if on_site_holding?
      return Flipflop.change_status? ? 'Available' : 'On-site Access'
    end
    return 'Some items not available' if holding['availability'] == 'check_holdings'
    return holding['availability'].titlecase if holding['availability']

    # For electronic holdings
    return holding['activation_status'].titlecase if holding['activation_status']
  end

  def on_site_holding?
    return true if aeon

    on_site_locations? || on_site_sc_locations?
  end

  # Holdings in these location are for on-site use only
  def on_site_locations?
    ['lewis$map', 'lewis$maplf', 'lewis$maplref', 'lewis$mapmc', 'lewis$mapmcm'].include?(library_location_code)
  end

  def on_site_sc_locations?
    additional_locations = ['rare$xmr', 'mudd$scamudd', 'rare$xrr',
                            'rare$xgr', 'rare$xcr', 'mudd$phr']
    library_location_code.start_with?('rare$sca') || additional_locations.include?(library_location_code)
  end

  def library_location_code
    "#{holding['library_code']}$#{holding['location_code']}"
  end
end
