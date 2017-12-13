# This migration comes from locations (originally 20150522175704)
class AddAdditionalFieldsToHoldingLocation < ActiveRecord::Migration[4.2]
  def change
    add_column :locations_holding_locations, :aeon_location, :boolean, default: false
    add_column :locations_holding_locations, :recap_electronic_delivery_location, :boolean, default: false
    add_column :locations_holding_locations, :open, :boolean, default: true
    add_column :locations_holding_locations, :requestable, :boolean, default: true
    add_column :locations_holding_locations, :always_requestable, :boolean, default: false
  end
end
