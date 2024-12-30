module PartnerFull
  # Callbacks for Sidekiq jobs for Full Partner reindexes
  class Callbacks
    def step1_done(status, options); end

    def all_steps_done(_status, options)
      event = Event.find(options['event_id'])
      event.finish = Time.now.utc
      event.success = true
      event.save!
    end
  end
end
