class AvailabilityController < ApplicationController

  def index
    if params[:ids]
      ids_param = sanitize_array(params[:ids])
      avail = VoyagerLookup.multiple_bib_availability(bib_ids: ids_param)

      if avail.empty?
        render plain: "Record(s): #{ids_param} not found.", status: 404
      else
        respond_to do |wants|
          wants.json  { render json: MultiJson.dump(avail) }
        end
      end
    elsif params[:id]
      id_param = sanitize(params[:id])
      avail = VoyagerLookup.single_bib_availability(bib_id: id_param)

      if avail.empty?
        render plain: "Record: #{id_param} not found.", status: 404
      else
        respond_to do |wants|
          wants.json  { render json: MultiJson.dump(avail) }
        end
      end
    elsif params[:mfhd]
      mfhd_param = sanitize(params[:mfhd])
      avail = VoyagerLookup.single_mfhd_availability(mfhd: mfhd_param.to_i)

      if avail.empty?
        render plain: "Record: #{mfhd_param} not found.", status: 404
      else
        respond_to do |wants|
          wants.json  { render json: MultiJson.dump(avail) }
        end
      end
    elsif params[:mfhd_serial]
      mfhd_serial_param = sanitize(params[:mfhd_serial])
      avail = VoyagerLookup.mfhd_serial_availability(mfhd_serial: mfhd_serial_param.to_i)

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
end
