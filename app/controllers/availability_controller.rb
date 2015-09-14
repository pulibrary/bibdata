class AvailabilityController < ApplicationController

  def index
    if params[:ids]
      record = VoyagerHelpers::Liberator.get_availability(sanitize_array(params[:ids]))
      if record.empty?
        render plain: "Item(s): #{params[:ids]} not found.", status: 404
      else
        respond_to do |wants|
          wants.json  { render json: MultiJson.dump(record) }
        end
      end
    else
      render plain: "Please provide a bib id.", status: 404
    end
  end
end



