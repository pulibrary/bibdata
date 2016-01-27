# This migration comes from locations (originally 20160127140802)
class AddDigitalLocationToDeliveryLocation < ActiveRecord::Migration
  def change
    add_column :locations_delivery_locations, :digital_location, :boolean
  end
end
