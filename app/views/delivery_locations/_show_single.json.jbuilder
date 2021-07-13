# frozen_string_literal: true

json.extract! delivery_location, :label, :address, :phone_number, :contact_email, :gfa_pickup, :staff_only, :pickup_location, :digital_location
# Presently no use case for seeing holding_locations from this side of the association
# json.holding_locations delivery_location.holding_locations do |holding_location|
#   json.partial! 'locations/holding_locations/show_single', holding_location: holding_location
# end
