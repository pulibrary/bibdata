# frozen_string_literal: true

json.array!(@hours_locations) do |hours_location|
  json.partial! 'hours_locations/show_single', hours_location: hours_location
  if Rails.env.test?
    # This is a not very good hack around
    # `Rails.application.routes.default_url_options[:host]` not being set.
    json.path hours_location_path(hours_location, format: :json)
  else
    json.url hours_location_url(hours_location, format: :json)
  end
end
