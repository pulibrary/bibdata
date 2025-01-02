module Partner
  module Import
    class StartWorkflowJob
      include Sidekiq::Job

      def perform(dump_id)
        # at this point batch should be the overall batch
        batch.jobs do
          download_step = Sidekiq::Batch.new
          download_step.description = "Download and process full partner files for dump: #{dump_id}"
          download_step.on(:success, 'Scsb::PartnerUpdates::Callback#finished_downloading', 'dump_id' => dump_id)
          download_step.jobs do
            institutions.each do |institution|
              params = { inst: institution[:inst], prefix: institution[:prefix], dump_id: }.stringify_keys
              DownloadAndProcessFullJob.perform_async(params)
            end
          end
        end
      end

      private

        def institutions
          [
            { inst: 'NYPL', prefix: 'scsbfull_nypl_' },
            { inst: 'CUL', prefix: 'scsbfull_cul_' },
            { inst: 'HL', prefix: 'scsbfull_hl_' }
          ]
        end
    end
  end
end
