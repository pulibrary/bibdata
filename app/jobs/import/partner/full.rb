module Import
  module Partner
    class Full
      include Sidekiq::Job
      def perform
        delete_stale_files

        Event.record do |event|
          event.save
          event.dump = created_dump(event)
          event.save!

          Scsb::PartnerUpdates.full(dump: event.dump)
        end
      end

      private

        def created_dump(event)
          Dump.create!(dump_type: :partner_recap_full, event_id: event.id)
        end

        def delete_stale_files
          update_directory = ENV.fetch('SCSB_PARTNER_UPDATE_DIRECTORY', '/tmp/updates')
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
