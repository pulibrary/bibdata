# This migration comes from locations (originally 20160218152356)
class AddCirculatesToLocationsHoldingLocations < ActiveRecord::Migration[4.2]
  def change
    add_column :locations_holding_locations, :circulates, :boolean, default: true
    reversible do |direction|
      direction.up { Locations::HoldingLocation.update_all(circulates: true) }
    end
  end
end
