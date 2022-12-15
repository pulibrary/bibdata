class BarcodeController < ApplicationController
  include FormattingConcern

  def index
    if params[:barcode]
      redirect_to action: :barcode, barcode: params[:barcode], status: :moved_permanently
    else
      render plain: "Please supply a barcode.", status: :not_found
    end
  end

  # Client: This endpoint is used by the ReCAP inventory management system, LAS,
  #   to pull data from our ILS when items are accessioned
  def scsb
    barcode = params[:barcode]
    if !valid_barcode?(barcode)
      render plain: "Barcode #{barcode} not valid.", status: :not_found
    else
      adapter = AlmaAdapter.new
      item = adapter.item_by_barcode(barcode)
      mms_id = item["bib_data"]["mms_id"]
      record = adapter.get_bib_record(mms_id, suppressed: false)

      # If the bib record is not found, the returned record will be nil and the controller should return with a 404 status
      if record.nil?
        render plain: "Record #{mms_id} not found", status: :not_found
        return
      end
      holding = adapter.holding_by_id(mms_id:, holding_id: item.holding_data["holding_id"])
      records = if record.linked_record_ids.present?
                  adapter.get_bib_records(record.linked_record_ids)
                else
                  [record]
                end
      records.each do |bib_record|
        bib_record.enrich_with_item(item)
        bib_record.delete_conflicting_holding_data!
        bib_record.enrich_with_holding(holding, recap: true)
        bib_record.strip_non_numeric!
      end
      if records == []
        render plain: "Barcode #{barcode} not found.", status: :not_found
      else
        respond_to do |wants|
          wants.json  do
            json = MultiJson.dump(pass_records_through_xml_parser(records))
            render json:
          end
          wants.xml do
            xml = records_to_xml_string(records)
            render xml:
          end
        end
      end
    end
  rescue => e
    handle_alma_exception(exception: e, message: "Error for barcode: #{barcode}")
  end
end
