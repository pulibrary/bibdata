require 'json/add/regexp'

# Step 1 of overall batch
# Performed within download_step batch
# Checks that the associated CSV is valid, then kicks off the DownloadPartnerFilesJob
class DownloadAndProcessFullJob
  include Sidekiq::Job
  def perform(params)
    batch.jobs do
      dump_id = params['dump_id']
      inst = params['inst']
      return false unless Scsb::PartnerUpdates::Full.validate_csv(inst:, dump_id:)

      # nosemgrep
      matcher = (/#{inst}.*\.zip/.as_json if ['CUL', 'HL', 'NYPL'].include?(inst))
      download_params = { file_filter: matcher, dump_id:, file_prefix: params['prefix'] }.stringify_keys
      DownloadPartnerFilesJob.perform_async(download_params)
    end
  end
end
