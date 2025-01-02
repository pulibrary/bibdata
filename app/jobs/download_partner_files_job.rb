require 'json/add/regexp'

# Downloads partner updates from S3, and kicks off the ProcessPartnerUpdatesJob if the files are successfully downloaded
class DownloadPartnerFilesJob
  include Sidekiq::Job
  def perform(params)
    Scsb::PartnerUpdates::Full.download_partner_files(
      file_filter: params['file_filter'],
      dump_id: params['dump_id'],
      file_prefix: params['file_prefix']
    )
  end
end
