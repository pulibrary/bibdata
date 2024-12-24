class AttachXmlFileJob
  include Sidekiq::Job
  def perform(params)
    Scsb::PartnerUpdates::Update.attach_cleaned_dump_file(
      file: params['file'],
      dump_id: params['dump_id'],
      file_prefix: params['file_prefix'],
      dump_file_type: :recap_records_full
    )
  end
end
