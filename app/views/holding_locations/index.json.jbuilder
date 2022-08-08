# frozen_string_literal: true

json.array!(@holding_locations) do |holding_location|
  json.partial! 'holding_locations/json_partials/show_fields',
                holding_location: holding_location

  if Rails.env.test?
    json.path holding_location_path(holding_location, format: :json)
  else
    json.url holding_location_url(holding_location, format: :json)
  end

  json.partial! 'holding_locations/json_partials/library',
                library: holding_location.library

  json.partial! 'holding_locations/json_partials/holding_library',
                holding_library: holding_location.holding_library
end
