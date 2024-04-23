class ScsbImportFullJob < ApplicationJob
  def perform
    delete_stale_files

    Event.record do |event|
      event.dump = created_dump
      event.save!

      Scsb::PartnerUpdates.full(dump: event.dump)
    end
  end

  private

    def created_dump
      Dump.create!(dump_type_id: 5)
    end

    def delete_stale_files
      FileUtils.rm Dir.glob("#{ENV['SCSB_PARTNER_UPDATE_DIRECTORY']}/*.zip")
      FileUtils.rm Dir.glob("#{ENV['SCSB_PARTNER_UPDATE_DIRECTORY']}/*.xml")
    end
end
