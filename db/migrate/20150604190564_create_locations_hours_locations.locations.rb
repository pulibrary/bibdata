# This migration comes from locations (originally 20150603170114)
class CreateLocationsHoursLocations < ActiveRecord::Migration[4.2]
  def change
    create_table :locations_hours_locations do |t|
      t.string :code
      t.string :label

      t.timestamps null: false
    end
  end
end
