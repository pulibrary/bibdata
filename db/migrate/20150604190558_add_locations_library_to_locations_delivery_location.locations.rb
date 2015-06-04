# This migration comes from locations (originally 20150520175207)
class AddLocationsLibraryToLocationsDeliveryLocation < ActiveRecord::Migration
  def change
    add_reference :locations_delivery_locations, :locations_library, index: true, foreign_key: true
  end
end
