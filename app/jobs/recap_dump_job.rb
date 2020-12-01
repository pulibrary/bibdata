require 'voyager_helpers'
require 'net/sftp'

class RecapDumpJob < ActiveJob::Base
  queue_as :default

  def perform(barcode_slice, df_id)
    # TODO: Re-enable. Disabled as we no longer have VoyagerHelpers.
    # df = DumpFile.find(df_id)
    # File.truncate(df.path, 0) if File.exist?(df.path)
    # # true is passed to make sure this returns recap flavored data
    # VoyagerHelpers::Liberator.dump_merged_records_to_file(barcode_slice, df.path, true)
    # df.zip
    # df.save
    # transfer_recap_dump_file(df)
  end

  def transfer_recap_dump_file(dump_file)
    key = File.basename(dump_file.path)
    @s3_bucket ||= Scsb::S3Bucket.new
    @s3_bucket.upload_file(key: key, file_path: dump_file.path)
  end
end
