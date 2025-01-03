module Import
  module Partner
    class FullCallbacks
      def overall_success(_status, options)
        event = Event.find(options['event_id'])
        event.success = true
        event.finish = Time.now.utc
        event.save!
      end

      def download_and_process_success(_status, options)
        Dump.generated_date(options['dump_id'])
      end
    end
  end
end
