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

    def dump_type
      @dump_type ||= DumpType.find_or_create_by!(constant: DumpType::PARTNER_RECAP_FULL)
    end

    def created_dump
      Dump.create!(dump_type:)
    end

    def delete_stale_files
      FileUtils.rm Dir.glob("#{ENV['SCSB_PARTNER_UPDATE_DIRECTORY']}/*.zip")
      FileUtils.rm Dir.glob("#{ENV['SCSB_PARTNER_UPDATE_DIRECTORY']}/*.xml")
    end
end
