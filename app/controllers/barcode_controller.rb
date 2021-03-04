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
    barcode = params[:barcode]
    if !valid_barcode?(barcode)
      render plain: "Barcode #{barcode} not valid.", status: 404
    else
      item = Alma::BibItem.find_by_barcode(barcode)
      if item["errorsExist"]
        render plain: item["errorList"]["error"].map { |e| e["errorMessage"] }, status: 404
        return
      end
      mms_id = item.item["bib_data"]["mms_id"]
      record = AlmaAdapter.new.get_bib_record(mms_id)

      # If the bib record is supressed, the returned record will be nil and the controller should return with a 404 status
      if record.nil?
        render plain: "Record #{mms_id} not found or suppressed", status: 404
        return
      end
      holding = Alma::BibHolding.find(mms_id: mms_id, holding_id: item.holding_data["holding_id"])
      records = if record.linked_record_ids.present?
                  AlmaAdapter.new.get_bib_records(record.linked_record_ids)
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
        render plain: "Barcode #{barcode} not found.", status: 404
      else
        respond_to do |wants|
          wants.json  do
            json = MultiJson.dump(pass_records_through_xml_parser(records))
            render json: json
          end
          wants.xml do
            xml = records_to_xml_string(records)
            render xml: xml
          end
        end
      end
    end
  end
end
