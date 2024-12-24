module Scsb
  class PartnerUpdates
    class Callback
      # called by batch.on(:success)
      def on_success(_status, options)
        event = Event.find(options['event_id'])
        event.success = true
        event.save!
        Scsb::PartnerUpdates::Update.generated_date(dump_id: event.dump.id)
      end

      def on_complete(status, options)
        event_id = options['event_id']
        event = Event.find(event_id)
        return unless status.failures != 0
        event.success = false
        event.error << "Sidekiq batch: #{status.bid} completed with errors for event_id: #{event_id}"
        event.save!
      end
    end
  end
end
