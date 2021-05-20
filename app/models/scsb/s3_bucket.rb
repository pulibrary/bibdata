module Scsb
  class S3Bucket
    attr_reader :s3_client, :s3_bucket_name

    def initialize(s3_client: Aws::S3::Client.new(region: 'us-east-2',
                                                  credentials: Aws::Credentials.new(ENV['SCSB_S3_ACCESS_KEY'], ENV['SCSB_S3_SECRET_ACCESS_KEY'])),
                   s3_bucket_name: ENV['SCSB_S3_BUCKET_NAME'])
      @s3_client = s3_client
      @s3_bucket_name = s3_bucket_name
    end

    def list_files(prefix:)
      objects = s3_client.list_objects(bucket: s3_bucket_name, prefix: prefix, delimiter: '')
      objects.contents
    end

    def download_file(key:)
      object = s3_client.get_object(bucket: s3_bucket_name, key: key)
      object.body
    end

    def upload_file(key:, file_path:, prefix: ENV['SCSB_S3_UPDATES'] || 'data-feed/submitcollections/PUL/cgd_protection')
      status = true
      File.open(file_path, 'rb') do |file|
        status && s3_client.put_object(bucket: s3_bucket_name, body: file, key: "#{prefix}/scsb_#{key}")
      end
      status
    rescue StandardError => e
      Rails.logger.warn("Error uploading object: #{e.message}")
      false
    end

    # @return [Array<String>] paths to the downloaded files
    def download_files(files:, timestamp_filter:, output_directory:, file_filter: /CUL-NYPL.*\.zip/)
      files_by_extension = files.select { |obj| obj.key.match?(file_filter) }
      files_to_download = files_by_extension.select { |obj| obj.last_modified > timestamp_filter }
      files_to_download.map do |obj|
        filename = File.basename(obj[:key])
        data = download_file(key: obj.key)
        dest = File.join(output_directory, filename)
        File.open(dest, 'wb') do |output|
          output.write(data.read)
        end
        dest
      end
    end
  end
end
