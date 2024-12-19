require 'json/add/regexp'

module Scsb
  class PartnerUpdates
    class Full < Update
      def initialize(dump:, dump_file_type:, timestamp: DateTime.now.to_time)
        super
      end

      def process_full_files
        prepare_directory
        download_and_process_full(inst: "NYPL", prefix: 'scsbfull_nypl_') # turn into job
        download_and_process_full(inst: "CUL", prefix: 'scsbfull_cul_') # turn into job
        download_and_process_full(inst: "HL", prefix: 'scsbfull_hl_') # turn into job
        set_generated_date
        log_record_fixes
      end

      def download_and_process_full(inst:, prefix:) # turn into job
        return false unless validate_csv(inst:)

        matcher = /#{inst}.*\.zip/.as_json
        DownloadPartnerFilesJob.perform_later(file_filter: matcher, dump_id: @dump.id, file_prefix: prefix)
      end

      # Ensures that CSV is present and that it does not include any private records
      def validate_csv(inst:)
        matcher = /#{inst}.*\.csv/.as_json
        file = download_full_file(matcher)
        matches_expected_collections = false
        if file
          csv = CSV.read(file, headers: true)
          matches_expected_collections = csv["Collection Group Id(s)"].first == '1*2*5*6'
          unless matches_expected_collections
            add_error(message: "Metadata file indicates that dump for #{inst} does not include the correct Group IDs, not processing. Group ids: #{csv['Collection Group Id(s)'].first}")
          end
          filename = File.basename(file)
          destination_filepath = "#{@scsb_file_dir}/#{filename}"
          FileUtils.move(file, destination_filepath)
          Dump.attach_dump_file(dump_id: dump.id, filepath: destination_filepath, dump_file_type: :recap_records_full_metadata)
          File.unlink(destination_filepath) if File.exist?(destination_filepath)
        else
          add_error(message: "No metadata files found matching #{inst}")
        end
        matches_expected_collections
      end

      def download_full_file(file_filter)
        file_filter = Regexp.json_create(file_filter)
        prefix = ENV['SCSB_S3_PARTNER_FULLS'] || 'data-exports/PUL/MARCXml/Full'
        @s3_bucket.download_recent(prefix:, output_directory: @update_directory, file_filter:)
      end
    end
  end
end
