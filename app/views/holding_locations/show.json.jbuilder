# frozen_string_literal: true

json.partial! 'holding_locations/json_partials/show_fields',
              holding_location: @holding_location

json.partial! 'holding_locations/json_partials/library',
              library: @holding_location.library

json.partial! 'holding_locations/json_partials/holding_library',
              holding_library: @holding_location.holding_library

json.partial! 'holding_locations/json_partials/delivery_locations',
              delivery_locations: @holding_location.delivery_locations
