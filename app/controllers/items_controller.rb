class ItemsController < ApplicationController
  include FormattingConcern

  def index
    if params[:item_id]
      redirect_to action: :item, item_id: params[:item_id], status: :moved_permanently
    else
      render plain: "Record please supply an item id.", status: 404
    end
  end

  def item
    record = VoyagerHelpers::Liberator.get_item(params[:item_id])
    if record.nil?
      render plain: "Item #{params[:item_id]} not found.", status: 404
    else
      respond_to do |wants|
        wants.json  { render json: MultiJson.dump(record) }
        wants.xml { render xml: '<todo but="You probably want JSON anyway" />' }
      end
    end
  end

end



