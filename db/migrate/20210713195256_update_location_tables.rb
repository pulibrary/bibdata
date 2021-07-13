class UpdateLocationTables < ActiveRecord::Migration[5.2]
  def change
    add_reference :delivery_locations, :library, index: true, foreign_key: true
    add_reference :holding_locations, :library, index: true, foreign_key: true
    add_reference :holding_locations, :hours_location, foreign_key: true
    add_foreign_key :holding_locations, :libraries, column: :holding_library_id
    add_index :holdings_delivery, :delivery_location_id, name: 'index_lhd_on_ldl_id'
    add_index :holdings_delivery, :holding_location_id, name: 'index_ldl_on_lhd_id'
  end
end
