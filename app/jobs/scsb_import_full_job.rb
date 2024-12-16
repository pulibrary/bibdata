class ScsbImportFullJob < ApplicationJob
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
      files_to_delete = Dir.glob("#{ENV['SCSB_PARTNER_UPDATE_DIRECTORY']}/*.zip")
                           .concat(Dir.glob("#{ENV['SCSB_PARTNER_UPDATE_DIRECTORY']}/*.xml"))
                           .concat(Dir.glob("#{ENV['SCSB_PARTNER_UPDATE_DIRECTORY']}/*.csv"))
      files_to_delete.each do |file|
        FileUtils.rm file
      rescue Errno::ENOENT
        Rails.logger.warn("Attempted to delete file #{file}, but it was no longer present on the filesystem")
        next
      end
    end
end
