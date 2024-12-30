require 'json/add/regexp'

# Checks that the associated CSV is valid, then kicks off the DownloadPartnerFilesJob, which in turn
# kicks off the ProcessPartnerUpdatesJob
class DownloadAndProcessFullJob
  include Sidekiq::Job
  def perform(params)
    @update_directory = ENV.fetch('SCSB_PARTNER_UPDATE_DIRECTORY', nil) || '/tmp/updates'
    @scsb_file_dir = ENV.fetch('SCSB_FILE_DIR', nil)
    dump_id = params['dump_id']
    inst = params['inst']
    return false unless Scsb::PartnerUpdates::Full.validate_csv(inst:, dump_id:)

    # nosemgrep
    matcher = (/#{inst}.*\.zip/.as_json if ['CUL', 'HL', 'NYPL'].include?(inst))
    download_params = { file_filter: matcher, dump_id:, file_prefix: params['prefix'] }.stringify_keys
    DownloadPartnerFilesJob.perform_async(download_params)
  end
end
