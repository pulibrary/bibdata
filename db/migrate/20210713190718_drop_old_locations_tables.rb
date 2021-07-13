class DropOldLocationsTables < ActiveRecord::Migration[5.2]
  def change
    drop_table :locations_delivery_locations, if_exists: true, force: :cascade
    drop_table :locations_libraries, if_exists: true, force: :cascade
    drop_table :locations_holding_locations, if_exists: true, force: :cascade
    drop_table :locations_hours_locations, if_exists: true, force: :cascade
  end
end
