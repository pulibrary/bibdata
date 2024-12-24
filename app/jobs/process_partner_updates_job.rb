# Extracts the xml files from the Partner zip files (previously downloaded from S3), and attaches the xml files to the associated dump
class ProcessPartnerUpdatesJob < ApplicationJob
  # Used for full dumps, since order does not matter for full dumps, unlike incremental dumps
  def perform(dump_id:, files:, file_prefix:)
    update_directory = ENV['SCSB_PARTNER_UPDATE_DIRECTORY'] || '/tmp/updates'
    files.each do |file|
      xml_files = Scsb::PartnerUpdates::Update.extract_files(file:, update_directory:)
      attach_xml_files(xml_files:, dump_id:, file_prefix:)
    end
  end

  def attach_xml_files(xml_files:, dump_id:, file_prefix:)
    xml_files.each do |xml_file|
      Scsb::PartnerUpdates::Update.attach_cleaned_dump_file(file: xml_file, dump_id:, file_prefix:, dump_file_type: :recap_records_full)
    end
  end
end
