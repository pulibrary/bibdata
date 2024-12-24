require 'json/add/regexp'

# Checks that the associated CSV is valid, then kicks off the DownloadPartnerFilesJob, which in turn
# kicks off the ProcessPartnerUpdatesJob
class DownloadAndProcessFullJob
  include Sidekiq::Job
  def perform(params)
    @update_directory = ENV['SCSB_PARTNER_UPDATE_DIRECTORY'] || '/tmp/updates'
    @scsb_file_dir = ENV['SCSB_FILE_DIR']
    dump_id = params['dump_id']
    inst = params['inst']
    return false unless Scsb::PartnerUpdates::Full.validate_csv(inst:, dump_id:)

    matcher = /#{inst}.*\.zip/.as_json
    download_params = { file_filter: matcher, dump_id:, file_prefix: params['prefix'] }.stringify_keys
    DownloadPartnerFilesJob.perform_async(download_params)
  end
end
