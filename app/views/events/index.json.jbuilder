json.array!(@events) do |event|
  json.extract! event, :id, :start, :finish, :error, :success, :dump_type
  json.url event_url(event, format: :json)
end
