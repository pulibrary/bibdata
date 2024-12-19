require 'json/add/regexp'

module Scsb
  class PartnerUpdates
    class Full < Update
      def initialize(dump:, dump_file_type:, timestamp: DateTime.now.to_time)
        super
      end

      def process_full_files
        prepare_directory
        DownloadAndProcessFullJob.perform_later(inst: "NYPL", prefix: 'scsbfull_nypl_', dump_id: @dump.id)
        DownloadAndProcessFullJob.perform_later(inst: "CUL", prefix: 'scsbfull_cul_', dump_id: @dump.id)
        DownloadAndProcessFullJob.perform_later(inst: "HL", prefix: 'scsbfull_hl_', dump_id: @dump.id)
        set_generated_date
        log_record_fixes
      end

      # Ensures that CSV is present and that it does not include any private records
      def self.validate_csv(inst:, dump_id:)
        @update_directory = ENV['SCSB_PARTNER_UPDATE_DIRECTORY'] || '/tmp/updates'
        @scsb_file_dir = ENV['SCSB_FILE_DIR']
        matcher = /#{inst}.*\.csv/.as_json
        file = Scsb::PartnerUpdates::Full.download_full_file(matcher)
        matches_expected_collections = false
        if file
          csv = CSV.read(file, headers: true)
          matches_expected_collections = csv["Collection Group Id(s)"].first == '1*2*5*6'
          unless matches_expected_collections
            add_error(message: "Metadata file indicates that dump for #{inst} does not include the correct Group IDs, not processing. Group ids: #{csv['Collection Group Id(s)'].first}", dump_id:)
          end
          filename = File.basename(file)
          destination_filepath = "#{@scsb_file_dir}/#{filename}"
          FileUtils.move(file, destination_filepath)
          Dump.attach_dump_file(dump_id:, filepath: destination_filepath, dump_file_type: :recap_records_full_metadata)
          File.unlink(destination_filepath) if File.exist?(destination_filepath)
        else
          add_error(message: "No metadata files found matching #{inst}", dump_id:)
        end
        matches_expected_collections
      end

      def self.add_error(message:, dump_id:)
        dump = Dump.find(dump_id)
        error = Array.wrap(dump.event.error)
        error << message
        dump.event.error = error.join("; ")
        dump.event.save
      end

      def self.download_full_file(file_filter)
        update_directory = ENV['SCSB_PARTNER_UPDATE_DIRECTORY'] || '/tmp/updates'
        prefix = ENV['SCSB_S3_PARTNER_FULLS'] || 'data-exports/PUL/MARCXml/Full'
        s3_bucket = Scsb::S3Bucket.partner_transfer_client
        file_filter = Regexp.json_create(file_filter)
        s3_bucket.download_recent(prefix:, output_directory: update_directory, file_filter:)
      end
    end
  end
end
