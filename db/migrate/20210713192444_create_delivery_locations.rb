class CreateDeliveryLocations < ActiveRecord::Migration[5.2]
  def change
    create_table :delivery_locations do |t|
      t.string :label
      t.text :address
      t.string :phone_number
      t.string :contact_email
      t.boolean :staff_only, default: false
      t.string :gfa_pickup
      t.boolean :pickup_location, default: false
      t.boolean :digital_location

      t.timestamps null: false
    end
  end
end
