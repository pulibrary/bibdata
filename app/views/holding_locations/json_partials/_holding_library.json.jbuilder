# frozen_string_literal: true

if holding_library
  json.holding_library do
    json.partial! 'libraries/show_single', library: holding_library
  end
else
  json.set! 'holding_library', holding_library
end
