# This migration comes from locations (originally 20150603212708)
class AddHoursLocToLocationsHoldingLocations < ActiveRecord::Migration
  def change
    add_reference :locations_holding_locations, :locations_hours_location, foreign_key: true
  end
end
