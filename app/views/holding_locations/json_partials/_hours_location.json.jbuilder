# frozen_string_literal: true

if hours_location
  json.hours_location do
    json.partial! 'hours_locations/show_single', hours_location: hours_location
  end
else
  json.set! 'hours_location', hours_location
end
