class ScsbImportJob < ApplicationJob
  include Scsb
  queue_as :default

  def perform(dump_id, timestamp)
    dump = Dump.find(dump_id)
    Scsb::PartnerUpdates.incremental(dump:, timestamp:)
  end
end
