require 'json/add/regexp'

class DownloadAndProcessFullJob < ApplicationJob
  def perform(inst:, prefix:, dump_id:)
    @update_directory = ENV['SCSB_PARTNER_UPDATE_DIRECTORY'] || '/tmp/updates'
    @scsb_file_dir = ENV['SCSB_FILE_DIR']
    return false unless Scsb::PartnerUpdates::Full.validate_csv(inst:, dump_id:)

    matcher = /#{inst}.*\.zip/.as_json
    DownloadPartnerFilesJob.perform_later(file_filter: matcher, dump_id:, file_prefix: prefix)
  end
end
