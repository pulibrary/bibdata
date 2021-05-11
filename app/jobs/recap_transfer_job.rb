require 'net/sftp'

class RecapTransferJob < ActiveJob::Base
  queue_as :default

  def perform(file_path)
    key = File.basename(file_path)
    s3_bucket.upload_file(key: key, file_path: file_path)
  end

  def s3_bucket
    @s3_bucket ||= Scsb::S3Bucket.new
  end
end
