class Event < ActiveRecord::Base
  has_one :dump

  before_destroy do
    self.dump.destroy unless self.dump.nil?
  end

  class << self
    def record
      event = Event.new
      event.start = Time.now.utc
      event.success = true
      yield(event)
    rescue Exception => e
      event.success = false
      event.error = "#{e.class}: #{e.message}"
      STDERR.puts e.message if defined?(Rake)
    ensure
      event.finish = Time.now.utc
      event.save!
      return event
    end
  end # class << self
end
