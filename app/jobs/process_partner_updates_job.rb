# Extracts the xml files from the Partner zip files (previously downloaded from S3), and attaches the xml files to the associated dump
class ProcessPartnerUpdatesJob
  include Sidekiq::Job
  # Used for full dumps, since order does not matter for full dumps, unlike incremental dumps
  def perform(params)
    update_directory = ENV.fetch('SCSB_PARTNER_UPDATE_DIRECTORY', nil) || '/tmp/updates'
    file_prefix = params['file_prefix']
    dump_id = params['dump_id']
    file = params['file']
    xml_files = Scsb::PartnerUpdates::Update.extract_files(file:, update_directory:)
    attach_xml_files(xml_files:, dump_id:, file_prefix:)
  end

  def attach_xml_files(xml_files:, dump_id:, file_prefix:)
    batch = Sidekiq::Batch.new
    batch.description = 'Attaches each xml file extracted from the zip file downloaded from S3'
    batch.on(:success, Scsb::PartnerUpdates::AttachXmlFileJobCallback, xml_files:)
    batch.jobs do
      xml_files.each do |xml_file|
        params = { file: xml_file, dump_id:, file_prefix: }.stringify_keys
        AttachXmlFileJob.perform_async(params)
      end
    end
  end
end
