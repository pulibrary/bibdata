class ScsbImportFullJob < ActiveJob::Base
  def perform
    event = Event.create
    event.dump = Dump.create(dump_type: DumpType.find_by(constant: 'PARTNER_RECAP_FULL'))
    event.save
    Scsb::PartnerUpdates.full(dump: event.dump)
  end
end
