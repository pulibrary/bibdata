class ScsbImportFullJob
  include Sidekiq::Job
  def perform
    prepare_directory
    delete_stale_files

    Event.record do |event|
      event.save
      event.dump = created_dump(event)
      event.save!
      dump_id = event.dump.id
      batch = Sidekiq::Batch.new
      batch.on(:success, Scsb::PartnerUpdates::Callback, event_id: event.id)
      batch.on(:complete, Scsb::PartnerUpdates::Callback, event_id: event.id)
      batch.jobs do
        institutions.each do |institution|
          params = { inst: institution[:inst], prefix: institution[:prefix], dump_id: }.stringify_keys
          DownloadAndProcessFullJob.perform_async(params)
        end
      end
    end
  end

  private

    def created_dump(event)
      Dump.create!(dump_type: :partner_recap_full, event_id: event.id)
    end

    def prepare_directory
      update_directory = ENV['SCSB_PARTNER_UPDATE_DIRECTORY'] || '/tmp/updates'
      FileUtils.mkdir_p(update_directory)
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

    def institutions
      [
        { inst: 'NYPL', prefix: 'scsbfull_nypl_' },
        { inst: 'CUL', prefix: 'scsbfull_cul_' },
        { inst: 'HL', prefix: 'scsbfull_hl_' }
      ]
    end
end
