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

  def update_item_loc(item)
    loc = get_holding_location(item[:on_reserve] || item[:location])
    unless loc.nil?
      item[:on_reserve] = location_full_display(loc) if item[:on_reserve]
      item[:status] = 'Limited' unless loc.circulates
    end
  end

end
