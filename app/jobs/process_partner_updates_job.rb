class ProcessPartnerUpdatesJob < ApplicationJob
  # Used for full dumps, since order does not matter for full dumps, unlike incremental dumps
  def perform(dump_id:, files:, file_prefix:, update_directory: '', scsb_file_dir: '')
    files.each do |file|
      xml_files = Scsb::PartnerUpdates::Update.extract_files(file:, update_directory:)
      xml_files.each do |xml_file|
        Scsb::PartnerUpdates::Update.attach_cleaned_dump_file(file: xml_file, dump_id:, scsb_file_dir:, file_prefix:, dump_file_type: :recap_records_full)
      end
    end
  end
end
