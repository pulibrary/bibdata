module Import
  module Partner
    class StartWorkflowJob
      include Sidekiq::Job
      def perform(dump_id)
        dump = Dump.find(dump_id)
        batch.jobs do
          institutions.each do |institution, prefix|
            validate_csv_batch = Sidekiq::Batch.new
            validate_csv_batch.description = "Ensure there are no private records included for institution #{institution}"
            validate_csv_batch.on(:success, 'Import::Partner::FullCallbacks#validate_csv_success', 'dump_id' => dump_id, 'institution' => institution, 'prefix' => prefix)
            validate_csv_batch.jobs do
              ValidateCsvJob.perform_async(dump_id, institution, prefix)
            end
          end
        end
      end

      private

        def institutions
          {
            'NYPL' => 'scsbfull_nypl_',
            'CUL' => 'scsbfull_cul_',
            'HL' => 'scsbfull_hl_'
          }
        end
    end
  end
end
