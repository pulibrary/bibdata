class BarcodeController < ApplicationController
  include FormattingConcern

  def index
    if params[:barcode]
      redirect_to action: :barcode, barcode: params[:barcode], status: :moved_permanently
    else
      render plain: "Record please supply a barcode.", status: 404
    end
  end

  def barcode
    unless valid_barcode(params[:barcode])
      render plain: "Barcode #{params[:barcode]} not valid.", status: 404
    else
      records = VoyagerHelpers::Liberator.get_records_from_barcode(sanitize(params[:barcode]))
      if records.nil?
        render plain: "Barcode #{params[:barcode]} not found.", status: 404
      else
        respond_to do |wants|
          wants.json  {
            json = MultiJson.dump(pass_records_through_xml_parser(records))
            render json: json
          }
          wants.xml {
            xml = records_to_xml_string(records)
            render xml: xml
          }
        end
      end
    end
  end
end
