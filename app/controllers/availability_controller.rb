class AvailabilityController < ApplicationController
  def index
    if params[:ids]
      avail = VoyagerHelpers::Liberator.get_availability(sanitize_array(params[:ids]))
      if avail.empty?
        render plain: "Record(s): #{params[:ids]} not found.", status: 404
      else
        respond_to do |wants|
          wants.json  { render json: MultiJson.dump(avail) }
        end
      end
    elsif params[:id]
      avail = VoyagerHelpers::Liberator.get_availability([sanitize(params[:id])], true)
      if avail.empty?
        render plain: "Record: #{params[:id]} not found.", status: 404
      else
        respond_to do |wants|
          wants.json  { render json: MultiJson.dump(avail) }
        end
      end
    elsif params[:mfhd]
      avail = VoyagerHelpers::Liberator.get_full_mfhd_availability(sanitize(params[:mfhd]).to_i)
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
end
