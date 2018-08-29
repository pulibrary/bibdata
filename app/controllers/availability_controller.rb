class AvailabilityController < ApplicationController

  def index
    if params[:ids]
      ids_param = sanitize_array(params[:ids])
      avail_response = find_availability(bib_ids: ids_param, full: false)
      avail = multiple_bib_circulation(avail_response)

      if avail.empty?
        render plain: "Record(s): #{ids_param} not found.", status: 404
      else
        respond_to do |wants|
          wants.json  { render json: MultiJson.dump(avail) }
        end
      end
    elsif params[:id]
      id_param = sanitize(params[:id])
      avail_response = find_availability(bib_ids: [id_param])
      avail = single_bib_circulation(avail_response)

      if avail.empty?
        render plain: "Record: #{id} not found.", status: 404
      else
        respond_to do |wants|
          wants.json  { render json: MultiJson.dump(avail) }
        end
      end
    elsif params[:mfhd]
      mfhd_param = sanitize(params[:mfhd])
      avail_response = find_availability(mfhd: mfhd_param.to_i)
      avail = single_mfhd_circulation(avail_response)

      if avail.empty?
        render plain: "Record: #{mfhd_param} not found.", status: 404
      else
        respond_to do |wants|
          wants.json  { render json: MultiJson.dump(avail) }
        end
      end
    elsif params[:mfhd_serial]
      mfhd_serial_param = sanitize(params[:mfhd_serial])
      avail = find_availability(mfhd_serial: mfhd_serial_param.to_i)

      if avail.empty?
        render plain: "No current issues found for record #{mfhd_serial_param}.", status: 404
      else
        respond_to do |wants|
          wants.json  { render json: MultiJson.dump(avail) }
        end
      end
    elsif params[:barcodes]
      scsb_lookup = ScsbLookup.new
      avail = scsb_lookup.find_by_barcodes(sanitize_array(params[:barcodes]))
      if avail.empty?
        render plain: "SCSB Barcodes(s): #{params[:barcodes]} not found.", status: 404
      else
        respond_to do |wants|
          wants.json  { render json: MultiJson.dump(avail) }
        end
      end
    elsif params[:scsb_id]
      scsb_lookup = ScsbLookup.new
      avail = scsb_lookup.find_by_id(sanitize(params[:scsb_id]))
      if avail.empty?
        render plain: "SCSB Record: #{params[:scsb_id]} not found.", status: 404
      else
        respond_to do |wants|
          wants.json  { render json: MultiJson.dump(avail) }
        end
      end
    else
      render plain: "Please provide a bib id.", status: 404
    end
  end

  private

  # Retrieves the availability status of a holding from Voyager
  # @param [Array<String>] bib_ids the IDs for bib. items
  # @param [Integer] mfhd the ID for MFHD information
  # @param [Integer] mfhd_serial the ID for MFHD information describing a series
  # @return [Hash] the response containing MFHDs (location and status information) for the requested item(s)
  def find_availability(bib_ids: nil, mfhd: nil, mfhd_serial: nil, full: true)
    return VoyagerHelpers::Liberator.get_current_issues(mfhd_serial) unless mfhd_serial.nil?
    return VoyagerHelpers::Liberator.get_full_mfhd_availability(mfhd) unless mfhd.nil?
    VoyagerHelpers::Liberator.get_availability(bib_ids, full)
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
    bib.each do |_mfhd_id, mfhd|
      update_item_loc(mfhd)
    end
    bib
  end

  def single_mfhd_circulation(mfhd)
    mfhd.each do |item|
      update_item_loc(item)
    end
    mfhd
  end

  def location_full_display(loc)
    loc.label == '' ? loc.library.label : loc.library.label + ' - ' + loc.label
  end

  def get_holding_location(loc_code)
    Locations::HoldingLocation.find_by(code: loc_code)
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

  # only recap non-aeon items retain the hold request status
  def scsb_status(loc, _status)
    if loc.library.code == 'recap' && !loc.aeon_location
      hold_request
    else
      not_charged
    end
  end

  def order_status?(status)
    !order_statuses.select { |s| status.match(s) }.empty?
  end

  def always_requestable_status(status)
    if order_status?(status)
      status
    elsif !available_statuses.include?(status)
      %(#{on_site} - #{status})
    else
      on_site
    end
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

  def display_status(status)
    if status.is_a?(Array)
      (status_priority & status).last
    else
      status
    end
  end

  # non-circulating items that are available should have status 'limited'
  # always requestable non-circulating items should always have 'limited' status,
  # even with unavailable Voyager status
  def location_based_status(loc, status)
    status = scsb_status(loc, status) if status == 'Hold Request'
    if loc.always_requestable
      always_requestable_status(status)
    elsif !loc.circulates
      non_circulating_status(status)
    else
      status
    end
  end

  def update_item_loc(item)
    item[:status] = display_status(item[:status])
    loc_code = item[:temp_loc] || item[:location]
    loc = get_holding_location(loc_code)
    unless loc.nil?
      item[:label] = location_full_display(loc)
      item[:status] = location_based_status(loc, item[:status]) unless order_status?(item[:status])
    end
  end
end
