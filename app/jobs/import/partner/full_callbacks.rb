module Import
  module Partner
    class FullCallbacks
      def overall_success(_status, options)
        event = Event.find(options['event_id'])
        event.success = true
        event.finish = Time.now.utc
        event.save!
      end
    end
  end
end
