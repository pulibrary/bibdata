module Import
  module Partner
    class FullCallbacks
      def overall_success(_status, options)
        event = Event.find(options['event_id'])
        Dump.generated_date(event.dump.id)
        event.success = true
        event.finish = Time.now.utc
        event.save!
      end

      def validate_csv_success(status, options)
        dump = Dump.find(options['dump_id'])
        overall = Sidekiq::Batch.new(status.parent_bid)
        overall.jobs do
          partner_updates = Scsb::PartnerUpdates::Full.new(dump:, dump_file_type: :recap_records_full)
          partner_updates.download_and_process_full(inst: options['institution'], prefix: options['prefix'])
        end
      end
    end
  end
end
