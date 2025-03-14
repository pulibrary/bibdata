class Event < ActiveRecord::Base
  has_one :dump
  validates :message_body, uniqueness: { allow_blank: true }

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
      warn e.message if defined?(Rake)
    ensure
      event.finish = Time.now.utc
      event.save!
      return event
    end
  end # class << self
end
