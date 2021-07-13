# frozen_string_literal: true

json.partial! 'locations/delivery_locations/show_single', delivery_location: @delivery_location

json.partial! 'locations/holding_locations/json_partials/library', library: @delivery_location.library
