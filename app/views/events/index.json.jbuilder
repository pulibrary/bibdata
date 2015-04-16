json.array!(@events) do |event|
  json.extract! event, :id, :start, :finish, :success, :error
  json.dump_type event.dump.dump_type.constant unless event.dump.nil?
  json.dump_url dump_url(event.dump, format: :json) unless event.dump.nil?
  # json.url event_url(event, format: :json)
end
