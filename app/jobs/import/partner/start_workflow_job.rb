module Import
  module Partner
    class StartWorkflowJob
      include Sidekiq::Job
      def perform(dump_id)
        dump = Dump.find(dump_id)
        partner_updates = Scsb::PartnerUpdates::Full.new(dump:, dump_file_type: :recap_records_full)
        partner_updates.process_full_files
        # institutions.each do |institution|
        #   validate csv
        #   download zip file
        #   unzip zip file
        #   run record fixes
        #   attach fixed xml files
        # end
      end
    end
  end
end
