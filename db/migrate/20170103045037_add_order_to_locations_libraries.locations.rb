# This migration comes from locations (originally 20161228195737)
class AddOrderToLocationsLibraries < ActiveRecord::Migration[4.2]
  def change
    add_column :locations_libraries, :order, :integer, default: 0
  end
end
