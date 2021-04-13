require 'net/sftp'

class RecapTransferJob < ActiveJob::Base
  queue_as :default

  def perform(dump_file)
    key = File.basename(dump_file.path)
    s3_bucket.upload_file(key: key, file_path: dump_file.path)
  end

  def s3_bucket
    @s3_bucket ||= Scsb::S3Bucket.new
  end
end
