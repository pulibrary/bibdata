# This migration comes from locations (originally 20150519154738)
class CreateLocationsDeliveryLocations < ActiveRecord::Migration
  def change
    create_table :locations_delivery_locations do |t|
      t.string :label
      t.text :address
      t.string :phone_number
      t.string :contact_email
      t.boolean :staff_only, default: false

      t.timestamps null: false
    end
  end
end
