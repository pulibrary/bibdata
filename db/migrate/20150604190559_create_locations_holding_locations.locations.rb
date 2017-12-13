# This migration comes from locations (originally 20150521202558)
class CreateLocationsHoldingLocations < ActiveRecord::Migration[4.2]
  def change
    create_table :locations_holding_locations do |t|
      t.string :label
      t.string :code

      t.timestamps null: false
    end
  end
end
