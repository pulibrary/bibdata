class AddFulfillmentUnitToHoldingLocations < ActiveRecord::Migration[5.2]
  def change
    add_column :locations_holding_locations, :fulfillment_unit, :string
  end
end
