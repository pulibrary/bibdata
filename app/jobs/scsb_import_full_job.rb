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
      FileUtils.rm Dir.glob("#{ENV['SCSB_PARTNER_UPDATE_DIRECTORY']}/*.zip")
      FileUtils.rm Dir.glob("#{ENV['SCSB_PARTNER_UPDATE_DIRECTORY']}/*.xml")
      FileUtils.rm Dir.glob("#{ENV['SCSB_PARTNER_UPDATE_DIRECTORY']}/*.csv")
    end
end
