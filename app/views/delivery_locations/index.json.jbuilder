# frozen_string_literal: true

json.array!(@delivery_locations) do |delivery_location|
  json.partial! 'delivery_locations/show_single', delivery_location: delivery_location
  if Rails.env.test?
    json.path delivery_location_path(delivery_location, format: :json)
  else
    json.url delivery_location_url(delivery_location, format: :json)
  end
  json.partial! 'holding_locations/json_partials/library',
                library: delivery_location.library
end
