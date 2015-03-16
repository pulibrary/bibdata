json.array!(@events) do |event|
  json.extract! event, :id, :start, :finish, :success, :error
  json.dump_type event.dump.dump_type.constant
  json.dump_url dump_url(event.dump, format: :json)
  # json.url event_url(event, format: :json)
end
