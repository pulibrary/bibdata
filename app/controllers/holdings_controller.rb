class HoldingsController < ApplicationController
  include FormattingConcern

  def index
    if params[:items_only] == '1'
      redirect_to action: :holding_items, holding_id: params[:holding_id], status: :moved_permanently
    elsif params[:items_only] == '0'
      redirect_to action: :holding, holding_id: params[:holding_id], status: :moved_permanently
    else
      render plain: "Record please supply a holding id.", status: 404
    end
  end

  def holding
    record = VoyagerHelpers::Liberator.get_holding_record(params[:holding_id])
    if record.nil?
      render plain: "Record #{params[:holding_id]} not found or suppressed.", status: 404
    else
      respond_to do |wants|
        wants.json  { render json: MultiJson.dump(pass_records_through_xml_parser(record)) }
        wants.xml { render xml: record.to_xml.to_s }
      end
    end
  end

  def holding_items
    records = VoyagerHelpers::Liberator.get_items_for_holding(params[:holding_id])
    if records.nil?
      render plain: "Holding #{params[:holding_id]} not found or suppressed.", status: 404
    else
      respond_to do |wants|
        wants.json  { render json: MultiJson.dump(records) }
        wants.xml { render xml: '<todo but="You probably want JSON anyway" />' }
      end
    end
  end

end



