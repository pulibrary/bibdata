class ScsbImportJob < ActiveJob::Base
  include Scsb
  queue_as :default

  def perform(dump_id)
    dump = Dump.find(dump_id)
    Scsb::PartnerUpdates.new(dump: dump).process_partner_files
  end
end
