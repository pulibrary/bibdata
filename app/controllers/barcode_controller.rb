class BarcodeController < ApplicationController
  include FormattingConcern

  def index
    if params[:barcode]
      redirect_to action: :barcode, barcode: params[:barcode], status: :moved_permanently
    else
      render plain: "Please supply a barcode.", status: 404
    end
  end

  def scsb
    # TODO: Re-enable. Disabled as we no longer have VoyagerHelpers.
    # if !valid_barcode?(params[:barcode])
    #   render plain: "Barcode #{params[:barcode]} not valid.", status: 404
    # else
    #   records = VoyagerHelpers::Liberator.get_records_from_barcode(sanitize(params[:barcode]), true)
    #   if records == []
    #     render plain: "Barcode #{params[:barcode]} not found.", status: 404
    #   else
    #     respond_to do |wants|
    #       wants.json  do
    #         json = MultiJson.dump(pass_records_through_xml_parser(records))
    #         render json: json
    #       end
    #       wants.xml do
    #         xml = records_to_xml_string(records)
    #         render xml: xml
    #       end
    #     end
    #   end
    # end
  end

  def barcode
    # TODO: Re-enable. Disabled as we no longer have VoyagerHelpers.
    # unless valid_barcode?(params[:barcode])
    #   render plain: "Barcode #{params[:barcode]} not valid.", status: 404
    # else
    #   records = VoyagerHelpers::Liberator.get_records_from_barcode(sanitize(params[:barcode]))
    #   if records == []
    #     render plain: "Barcode #{params[:barcode]} not found.", status: 404
    #   else
    #     respond_to do |wants|
    #       wants.json  do
    #         json = MultiJson.dump(pass_records_through_xml_parser(records))
    #         render json: json
    #       end
    #       wants.xml do
    #         xml = records_to_xml_string(records)
    #         render xml: xml
    #       end
    #     end
    #   end
    # end
  end
end
