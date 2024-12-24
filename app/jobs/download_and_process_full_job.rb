require 'json/add/regexp'

# Checks that the associated CSV is valid, then kicks off the DownloadPartnerFilesJob, which in turn
# kicks off the ProcessPartnerUpdatesJob
class DownloadAndProcessFullJob < ApplicationJob
  def perform(inst:, prefix:, dump_id:)
    return false unless Scsb::PartnerUpdates::Full.validate_csv(inst:, dump_id:)

    matcher = /#{inst}.*\.zip/.as_json
    DownloadPartnerFilesJob.perform_later(file_filter: matcher, dump_id:, file_prefix: prefix)
  end
end
