module Import
  module Partner
    class Full
      include Sidekiq::Job

      def perform
        FileUtils.mkdir_p(update_directory)
        delete_stale_files
        event = Event.new
        event.start = Time.now.utc
        event.save!
        event.dump = created_dump(event)
        event.save!
        overall = Sidekiq::Batch.new
        overall.description = "Full partner update process for event: #{event.id}"
        overall.on(:success, 'Import::Partner::FullCallbacks#overall_success', 'event_id' => event.id)
        overall.jobs do
          Import::Partner::StartWorkflowJob.perform_async(event.dump.id)
        end
      end

      private

        def update_directory
          ENV.fetch('SCSB_PARTNER_UPDATE_DIRECTORY', '/tmp/updates')
        end

        def created_dump(event)
          Dump.create!(dump_type: :partner_recap_full, event_id: event.id)
        end

        def delete_stale_files
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
end
