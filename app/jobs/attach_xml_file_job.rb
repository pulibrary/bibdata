class AttachXmlFileJob < ApplicationJob
  def perform(file: , dump_id:, file_prefix:, dump_file_type: :recap_records_full)
    Scsb::PartnerUpdates::Update.attach_cleaned_dump_file(file:, dump_id:, file_prefix:, dump_file_type: :recap_records_full)
  end
end
