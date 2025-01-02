module Partner
  module Import
    class FullJob
      include Sidekiq::Job
      def perform
        prepare_directory
        delete_stale_files

        Event.record do |event|
          event.save
          event.dump = created_dump(event)
          event.save!
          dump_id = event.dump.id
          overall = Sidekiq::Batch.new
          overall.on(:success, Scsb::PartnerUpdates::Callback, event_id: event.id)
          overall.on(:complete, Scsb::PartnerUpdates::Callback, event_id: event.id)
          overall.description = "Full partner update process for event: #{event.id}"
          overall.jobs do
            StartWorkflowJob.perform_async(dump_id)
          end
        end
      end

      private

        def created_dump(event)
          Dump.create!(dump_type: :partner_recap_full, event_id: event.id)
        end

        def prepare_directory
          update_directory = ENV.fetch('SCSB_PARTNER_UPDATE_DIRECTORY', nil) || '/tmp/updates'
          FileUtils.mkdir_p(update_directory)
        end

        def delete_stale_files
          files_to_delete = Dir.glob("#{ENV.fetch('SCSB_PARTNER_UPDATE_DIRECTORY', nil)}/*.zip")
                               .concat(Dir.glob("#{ENV.fetch('SCSB_PARTNER_UPDATE_DIRECTORY', nil)}/*.xml"))
                               .concat(Dir.glob("#{ENV.fetch('SCSB_PARTNER_UPDATE_DIRECTORY', nil)}/*.csv"))
          files_to_delete.each do |file|
            FileUtils.rm file
          rescue Errno::ENOENT
            Rails.logger.warn("Attempted to delete file #{file}, but it was no longer present on the filesystem")
            next
          end
        end
    end
  end
end
