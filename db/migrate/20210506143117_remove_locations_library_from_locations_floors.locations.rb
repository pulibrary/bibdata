# This migration comes from locations (originally 20171213175117)
class RemoveLocationsLibraryFromLocationsFloors < ActiveRecord::Migration[4.2]
  def change
    remove_reference :locations_floors, :locations_library, foreign_key: true
  end
end
