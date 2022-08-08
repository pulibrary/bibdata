class DropLocationsHoursLocations < ActiveRecord::Migration[6.1]
  def change
    drop_table :locations_hours_locations, force: :cascade, if_exists: true
    remove_column :locations_holding_locations, :locations_hours_location_id, if_exists: true
  end
end
