module Scsb
  class PartnerUpdates
    class Full < Update
      def initialize(dump:, dump_file_type:, timestamp: DateTime.now.to_time)
        super
      end

      def self.validate_csv(dump_id, file, institution)
        matches_expected_collections = false
        raise StandardError, "No metadata files found matching #{institution}" unless file

        csv = CSV.read(file, headers: true)
        group_ids = csv['Collection Group Id(s)'].first
        matches_expected_collections = group_ids == '1*2*5*6'
        filename = File.basename(file)
        scsb_file_dir = ENV['SCSB_FILE_DIR']
        destination_filepath = "#{scsb_file_dir}/#{filename}"
        FileUtils.move(file, destination_filepath)
        Dump.attach_dump_file(dump_id, destination_filepath, :recap_records_full_metadata)
        File.unlink(destination_filepath) if File.exist?(destination_filepath)
        unless matches_expected_collections
          raise StandardError, "Metadata file indicates that dump for #{institution} does not include the correct Group IDs, not processing. Group ids: #{group_ids}"
        end

        matches_expected_collections
      end

      def download_full_file(file_filter)
        prefix = ENV['SCSB_S3_PARTNER_FULLS'] || 'data-exports/PUL/MARCXml/Full'
        @s3_bucket.download_recent(prefix:, output_directory: @update_directory, file_filter:)
      end

      def self.download_full_file(institution, extension)
        Scsb::S3Bucket.partner_transfer_client.download_recent(
          prefix: ENV['SCSB_S3_PARTNER_FULLS'] || 'data-exports/PUL/MARCXml/Full',
          output_directory: ENV['SCSB_PARTNER_UPDATE_DIRECTORY'] || '/tmp/updates',
          file_filter: /#{institution}.*\.#{extension}/
        )
      end
    end
  end
end
