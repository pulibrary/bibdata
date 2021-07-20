# frozen_string_literal: true

json.array!(@libraries) do |library|
  json.partial! 'libraries/show_single', library: library
  if Rails.env.test?
    # This is a not very good hack around
    # `Rails.application.routes.default_url_options[:host]` not being set.
    json.path library_path(library, format: :json)
  else
    json.url library_url(library, format: :json)
  end
end
