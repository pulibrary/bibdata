class BarcodeController < ApplicationController
  include FormattingConcern

  def index
    if params[:barcode]
      redirect_to action: :barcode, barcode: params[:barcode], status: :moved_permanently
    else
      render plain: "Please supply a barcode.", status: 404
    end
  end

  # TODO: Add SCSB record enrichments. See
  # https://github.com/pulibrary/voyager_helpers/blob/e468d9ae29367d74ba7e09620238e801a7ce7bad/lib/voyager_helpers/liberator.rb#L1108-L1127
  def scsb
    if !valid_barcode?(params[:barcode])
      render plain: "Barcode #{params[:barcode]} not valid.", status: 404
    else
      item = Alma::BibItem.find_by_barcode(params[:barcode])
      holding = Alma::BibHolding.find(mms_id: item.item["bib_data"]["mms_id"], holding_id: item.holding_data["holding_id"])
      record = AlmaAdapter.new.get_bib_record(item.item["bib_data"]["mms_id"])
      records = if record.linked_record_ids.present?
                  AlmaAdapter.new.get_bib_records(record.linked_record_ids)
                else
                  [record]
                end
      records.each do |bib_record|
        bib_record.enrich_with_item(item)
        bib_record.delete_conflicting_holding_data!
        bib_record.enrich_with_holding(holding, recap: true)
      end
      if records == []
        render plain: "Barcode #{params[:barcode]} not found.", status: 404
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

  def barcode
    render plain: "Deprecated endpoint", status: 410
  end
end
