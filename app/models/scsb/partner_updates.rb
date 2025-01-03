require 'json'

module Scsb
  class PartnerUpdates
    def self.incremental(dump:, timestamp:)
      dump_file_type = :recap_records
      partner_updates = Scsb::PartnerUpdates::Incremental.new(dump:, dump_file_type:, timestamp:)
      partner_updates.process_incremental_files
    end
  end
end
