# This migration comes from locations (originally 20150521221100)
class AddLocationsHoldingsDeliveryJoin < ActiveRecord::Migration[4.2]
  def change
    create_table :locations_holdings_delivery, id: false do |t|
      t.integer :locations_delivery_location_id, index: false
      t.integer :locations_holding_location_id, index: false
    end
    add_index :locations_holdings_delivery, :locations_delivery_location_id, name: 'index_lhd_on_ldl_id'
    add_index :locations_holdings_delivery, :locations_holding_location_id, name: 'index_ldl_on_lhd_id'
  end
end
