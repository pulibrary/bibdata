module Import
  module Partner
    class StartWorkflowJob
      include Sidekiq::Job
      def perform(dump_id)
        dump = Dump.find(dump_id)
        partner_updates = Scsb::PartnerUpdates::Full.new(dump:, dump_file_type: :recap_records_full)
        batch.jobs do
          download_and_process_batch = Sidekiq::Batch.new
          download_and_process_batch.description = 'Download partner records from S3'
          download_and_process_batch.on(:success, 'Import::Partner::FullCallbacks#download_and_process_success', 'dump_id' => dump.id)
          download_and_process_batch.jobs do
            partner_updates.download_and_process_full(inst: 'NYPL', prefix: 'scsbfull_nypl_')
            partner_updates.download_and_process_full(inst: 'CUL', prefix: 'scsbfull_cul_')
            partner_updates.download_and_process_full(inst: 'HL', prefix: 'scsbfull_hl_')
          end
        end
      end
    end
  end
end
