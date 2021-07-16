class ScsbImportFullJob < ActiveJob::Base
  def perform
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
      Dump.create!(dump_type: dump_type)
    end
end
