require 'json/add/regexp'

class DownloadPartnerFilesJob < ApplicationJob
  def perform(file_filter:, dump_id:, file_prefix:)
    file = Scsb::PartnerUpdates::Full.download_full_file(file_filter)
    if file
      @update_directory = ENV['SCSB_PARTNER_UPDATE_DIRECTORY'] || '/tmp/updates'
      @scsb_file_dir = ENV['SCSB_FILE_DIR']
      ProcessPartnerUpdatesJob.perform_later(
        dump_id:,
        files: [file.to_s],
        file_prefix:,
        update_directory: @update_directory.to_s,
        scsb_file_dir: @scsb_file_dir
      )
    else
      Scsb::PartnerUpdates::Full.add_error(message: "No full dump files found matching #{file_filter}", dump_id:)
    end
  end
end
