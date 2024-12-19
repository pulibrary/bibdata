require 'json/add/regexp'

# Downloads partner updates from S3, and kicks off the ProcessPartnerUpdatesJob if the files are successfully downloaded
class DownloadPartnerFilesJob < ApplicationJob
  def perform(file_filter:, dump_id:, file_prefix:)
    Scsb::PartnerUpdates::Full.download_partner_files(file_filter:, dump_id:, file_prefix:)
  end
end
