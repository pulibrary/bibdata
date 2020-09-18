class VoyagerLookup
  class << self
    # Retrieves the availability status of a holding from Voyager
    # @param [Array<String>] bib_ids the IDs for bib. items
    # @return [Hash] the response containing MFHDs (location and status information) for the requested item(s)
    def multiple_bib_availability(bib_ids:, full: false)
      availability = VoyagerHelpers::Liberator.get_availability(bib_ids, full)
      multiple_bib_circulation(availability)
    rescue OCIError => oci_error
      Rails.logger.error "Error encountered when requesting availability status: #{oci_error}"
      {}
    end

    # Retrieves the availability status of a holding from Voyager
    # @param [String] bib_id the IDs for bib. item
    # @return [Hash] the response containing MFHDs (location and status information) for the requested item(s)
    def single_bib_availability(bib_id:, full: true)
      availability = VoyagerHelpers::Liberator.get_availability([bib_id], full)
      single_bib_circulation(availability)
    rescue OCIError => oci_error
      Rails.logger.error "Error encountered when requesting availability status: #{oci_error}"
      {}
    end

    # Retrieves the availability status of a holding from Voyager
    # @param [Integer] mfhd the ID for MFHD information
    # @return [Hash] the response containing MFHDs (location and status information) for the requested item(s)
    def single_mfhd_availability(mfhd:)
      availability = VoyagerHelpers::Liberator.get_full_mfhd_availability(mfhd)
      single_mfhd_circulation(availability)
    rescue OCIError => oci_error
      Rails.logger.error "Error encountered when requesting availability status: #{oci_error}"
      {}
    end

    # Retrieves the availability status of a holding from Voyager
    # @param [Integer] mfhd_serial the ID for MFHD information describing a series
    # @return [Hash] the response containing MFHDs (location and status information) for the requested item(s)
    def mfhd_serial_availability(mfhd_serial:)
      VoyagerHelpers::Liberator.get_current_issues(mfhd_serial)
    rescue OCIError => oci_error
      Rails.logger.error "Error encountered when requesting availability status: #{oci_error}"
      {}
    end

    def multiple_bib_circulation(bibs)
      bibs.each do |_bib_id, bib|
        bib = single_bib_circulation(bib)
      end
    end

    def single_bib_circulation(bib)
      return [] if bib.nil?
      bib.each do |_mfhd_id, mfhd|
        update_item_values(mfhd)
      end
      bib
    end

    def single_mfhd_circulation(mfhd)
      return [] if mfhd.nil?
      mfhd.each do |item|
        update_item_values(item)
      end
      mfhd
    end

    def update_item_values(item)
      loc = get_holding_location(item)
      item[:label] = location_full_display(loc) unless loc.nil?
      item[:status] = context_based_status(loc, item[:status])
    end

    def get_holding_location(item)
      loc_code = item[:temp_loc] || item[:location]
      Locations::HoldingLocation.find_by(code: loc_code)
    end

    def location_full_display(loc)
      loc.label == '' ? loc.library.label : loc.library.label + ' - ' + loc.label
    end

    # non-circulating items that are available should have status 'limited'
    # always requestable non-circulating items should always have 'limited' status,
    # even with unavailable Voyager status
    def context_based_status(loc, status)
      status = initial_status(status)
      return status unless loc
      return status if order_status?(status)
      status = hold_status(loc, status)
      if loc.always_requestable
        on_site_status(status)
      elsif !loc.circulates
        non_circulating_status(status)
      else
        status
      end
    end

    def initial_status(status)
      if status.is_a?(Array)
        (status_priority & status).last
      else
        status
      end
    end

    def order_status?(status)
      !order_statuses.select { |s| status.match(s) }.empty?
    end

    # only recap non-aeon items retain the hold request status
    def hold_status(loc, status)
      return status unless status == 'Hold Request'
      if loc.library.code == 'recap' && !loc.aeon_location
        hold_request
      else
        not_charged
      end
    end

    def on_site_status(status)
      return on_site if available_statuses.include?(status)
      "#{on_site} - #{status}"
    end

    def non_circulating_status(status)
      if available_statuses.include?(status)
        on_site
      else
        status
      end
    end

    def status_priority
      ['Not Charged', 'Discharged', 'In Process', 'Hold Request', 'Charged', 'Renewed', 'Overdue',
       'On Hold', 'In Transit', 'In Transit On Hold', 'In Transit Discharged', 'Withdrawn',
       'Claims Returned', 'Lost--Library Applied', 'Missing', 'Lost--System Applied']
    end

    def available_statuses
      ['Not Charged', 'On Shelf']
    end

    def order_statuses
      ['Order Received', 'Pending Order', 'On-Order']
    end

    def not_charged
      'Not Charged'
    end

    def hold_request
      'Hold Request'
    end

    def on_site
      'On-Site'
    end
  end
end
