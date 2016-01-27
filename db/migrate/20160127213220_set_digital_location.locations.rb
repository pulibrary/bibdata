# This migration comes from locations (originally 20160127155209)
class SetDigitalLocation < ActiveRecord::Migration
  def change
    Locations::DeliveryLocation.update_all("digital_location=pickup_location")
  end
end
