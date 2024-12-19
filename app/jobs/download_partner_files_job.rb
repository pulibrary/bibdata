require 'json/add/regexp'

class DownloadPartnerFilesJob < ApplicationJob
  def perform(file_filter:, dump_id:, file_prefix:)
    file = download_full_file(file_filter)
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
      @dump = Dump.find(dump_id)
      add_error(message: "No full dump files found matching #{file_filter}")
    end
  end

  def download_full_file(file_filter)
    s3_bucket = Scsb::S3Bucket.partner_transfer_client
    file_filter = Regexp.json_create(file_filter)
    prefix = ENV['SCSB_S3_PARTNER_FULLS'] || 'data-exports/PUL/MARCXml/Full'
    s3_bucket.download_recent(prefix:, output_directory: @update_directory, file_filter:)
  end

  def add_error(message:)
    error = Array.wrap(@dump.event.error)
    error << message
    @dump.event.error = error.join("; ")
    @dump.event.save
  end
end
