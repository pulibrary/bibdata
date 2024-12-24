# Extracts the xml files from the Partner zip files (previously downloaded from S3), and attaches the xml files to the associated dump
class ProcessPartnerUpdatesJob < ApplicationJob
  # Used for full dumps, since order does not matter for full dumps, unlike incremental dumps
  def perform(dump_id:, files:, file_prefix:)
    update_directory = ENV['SCSB_PARTNER_UPDATE_DIRECTORY'] || '/tmp/updates'
    files.each do |file|
      xml_files = Scsb::PartnerUpdates::Update.extract_files(file:, update_directory:)
      batch = Sidekiq::Batch.new
      batch.on(:success, Scsb::PartnerUpdates::AttachXmlFileJobCallback, xml_files:)
      batch.jobs do
        xml_files.each do |xml_file|
          AttachXmlFileJob.perform_later(file: xml_file, dump_id:, file_prefix:, dump_file_type: :recap_records_full)
        end
      end
    end
  end
end
