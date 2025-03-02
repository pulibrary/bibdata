class AvailabilityController < ApplicationController
  def adapter
    @adapter ||= AlmaAdapter.new
  end

  def index
    if params[:ids] || params[:id] || params[:mfhd] || params[:mfhd_serial]
      render plain: 'This endpoint no longer accepts this param', status: :bad_request
    elsif params[:barcodes]
      scsb_lookup = ScsbLookup.new
      avail = scsb_lookup.find_by_barcodes(sanitize_array(params[:barcodes]))
      if avail.empty?
        render plain: "SCSB Barcodes(s): #{params[:barcodes]} not found.", status: :not_found
      else
        respond_to do |wants|
          wants.json  { render json: MultiJson.dump(avail) }
        end
      end
    elsif params[:scsb_id]
      scsb_lookup = ScsbLookup.new
      avail = scsb_lookup.find_by_id(CGI.escape(params[:scsb_id]))
      if avail.empty?
        render plain: "SCSB Record: #{params[:scsb_id]} not found.", status: :not_found
      else
        respond_to do |wants|
          wants.json  { render json: MultiJson.dump(avail) }
        end
      end
    else
      render plain: 'Please provide a bib id.', status: :not_found
    end
  end

  private

    def sanitize_array(arr)
      arr.map { |s| CGI.escape(s) }
    end
end
