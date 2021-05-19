class RecapTransferService
  def self.transfer(file_path:)
    new(file_path: file_path).transfer
  end

  attr_reader :file_path
  def initialize(file_path:)
    @file_path = file_path
  end

  def transfer
    key = File.basename(file_path)
    s3_bucket.upload_file(key: key, file_path: file_path)
  end

  private

    def s3_bucket
      @s3_bucket ||= Scsb::S3Bucket.new
    end
end
