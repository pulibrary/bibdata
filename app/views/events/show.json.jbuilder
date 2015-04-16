json.extract! @event, :id, :start, :finish, :error, :success, :created_at, :updated_at
json.dump_type @event.dump.dump_type.constant unless @event.dump.nil?
json.dump_url dump_url(@event.dump, format: :json) unless @event.dump.nil?
