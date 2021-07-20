class CreateHoldingsDelivery < ActiveRecord::Migration[5.2]
  def change
    create_table :holdings_delivery do |t|
      t.integer :delivery_location_id
      t.integer :holding_location_id
    end
  end
end
