# frozen_string_literal: true

json.delivery_locations delivery_locations do |delivery_location|
  json.partial! 'delivery_locations/show_single', delivery_location: delivery_location
  json.library do
    json.partial! 'libraries/show_single', library: delivery_location.library
  end
end
