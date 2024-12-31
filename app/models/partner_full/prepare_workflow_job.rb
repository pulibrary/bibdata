module PartnerFull
  class PrepareWorkflowJob
    include Sidekiq::Job

    def perform
      event = prepare_event
      prepare_directory
      overall = Sidekiq::Batch.new
      overall.description = "Overarching batch for for event #{event.id}"
      overall.on(:success, 'PartnerFull::Callbacks#all_steps_done', 'event_id' => event.id)
      overall.jobs do
        PartnerFull::StartWorkflowJob.perform_async(event.id)
      end
    end

    private

      def prepare_event
        event = Event.new
        event.start = Time.now.utc
        event.save!
        event.dump = Dump.create!(dump_type: :partner_recap_full, event_id: event.id)
        event.save!
        event
      end

      def prepare_directory
        update_directory = ENV.fetch('SCSB_PARTNER_UPDATE_DIRECTORY', '/tmp/updates')
        FileUtils.mkdir_p(update_directory)
        delete_stale_files(update_directory)
      end

      def delete_stale_files(update_directory)
        files_to_delete = Dir.glob("#{update_directory}/*.zip")
                             .concat(Dir.glob("#{update_directory}/*.xml"))
                             .concat(Dir.glob("#{update_directory}/*.csv"))
        files_to_delete.each do |file|
          FileUtils.rm file
        rescue Errno::ENOENT
          Rails.logger.warn("Attempted to delete file #{file}, but it was no longer present on the filesystem")
          next
        end
      end
  end
end
