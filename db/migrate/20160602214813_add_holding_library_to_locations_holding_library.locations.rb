# This migration comes from locations (originally 20160526020836)
class AddHoldingLibraryToLocationsHoldingLibrary < ActiveRecord::Migration[4.2]
  def change
    add_column :locations_holding_locations, :holding_library_id, :integer, index: true
    add_foreign_key :locations_holding_locations, :locations_libraries, column: :holding_library_id
  end
end
