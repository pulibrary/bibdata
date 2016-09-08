class AvailabilityController < ApplicationController
  def index
    if params[:ids]
      avail = VoyagerHelpers::Liberator.get_availability(sanitize_array(params[:ids]))
      avail = multiple_bib_circulation(avail)
      if avail.empty?
        render plain: "Record(s): #{params[:ids]} not found.", status: 404
      else
        respond_to do |wants|
          wants.json  { render json: MultiJson.dump(avail) }
        end
      end
    elsif params[:id]
      avail = VoyagerHelpers::Liberator.get_availability([sanitize(params[:id])], true)
      avail = single_bib_circulation(avail)
      if avail.empty?
        render plain: "Record: #{params[:id]} not found.", status: 404
      else
        respond_to do |wants|
          wants.json  { render json: MultiJson.dump(avail) }
        end
      end
    elsif params[:mfhd]
      avail = VoyagerHelpers::Liberator.get_full_mfhd_availability(sanitize(params[:mfhd]).to_i)
      avail = single_mfhd_circulation(avail)
      if avail.empty?
        render plain: "Record: #{params[:mfhd]} not found.", status: 404
      else
        respond_to do |wants|
          wants.json  { render json: MultiJson.dump(avail) }
        end
      end
    elsif params[:mfhd_serial]
      avail = VoyagerHelpers::Liberator.get_current_issues(sanitize(params[:mfhd_serial]).to_i)
      if avail.empty?
        render plain: "No current issues found for record #{params[:mfhd_serial]}.", status: 404
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

  def multiple_bib_circulation(bibs)
    bibs.each do |bib_id, bib|
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

  def on_site
    'On-Site'
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

  # non-circulating items that are available should have status 'limited'
  # always requestable non-circulating items should always have 'limited' status,
  # even with unavailable Voyager status
  def location_based_status(loc, status)
    if loc.always_requestable
      always_requestable_status(status)
    elsif !loc.circulates
      non_circulating_status(status)
    else
      status
    end
  end

  def update_item_loc(item)
    loc = get_holding_location(item[:temp_loc] || item[:location])
    unless loc.nil?
      item[:on_reserve] = location_full_display(loc)
      item[:label] = item[:on_reserve]
      item[:status] = location_based_status(loc, item[:status])
    end
  end
end
