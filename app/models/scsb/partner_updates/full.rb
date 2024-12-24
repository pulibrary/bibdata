module Scsb
  class PartnerUpdates
    class Full < Update
      def initialize(dump:, dump_file_type:, timestamp: DateTime.now.to_time)
        super
      end

      def process_full_files
        prepare_directory
        download_and_process_full(inst: 'NYPL', prefix: 'scsbfull_nypl_')
        download_and_process_full(inst: 'CUL', prefix: 'scsbfull_cul_')
        download_and_process_full(inst: 'HL', prefix: 'scsbfull_hl_')
        set_generated_date
        log_record_fixes
      end

      def download_and_process_full(inst:, prefix:)
        return false unless validate_csv(inst:)

        matcher = /#{inst}.*\.zip/
        file = download_full_file(matcher)
        if file
          process_partner_updates(files: [file], file_prefix: prefix)
        else
          add_error(message: "No full dump files found matching #{inst}")
        end
      end

      def validate_csv(inst:)
        matcher = /#{inst}.*\.csv/
        file = download_full_file(matcher)
        matches_expected_collections = false
        if file
          csv = CSV.read(file, headers: true)
          matches_expected_collections = csv['Collection Group Id(s)'].first == '1*2*5*6'
          unless matches_expected_collections
            add_error(message: "Metadata file indicates that dump for #{inst} does not include the correct Group IDs, not processing. Group ids: #{csv['Collection Group Id(s)'].first}")
          end
          filename = File.basename(file)
          destination_filepath = "#{@scsb_file_dir}/#{filename}"
          FileUtils.move(file, destination_filepath)
          attach_dump_file(destination_filepath, dump_file_type: :recap_records_full_metadata)
          File.unlink(destination_filepath) if File.exist?(destination_filepath)
        else
          add_error(message: "No metadata files found matching #{inst}")
        end
        matches_expected_collections
      end

      def download_full_file(file_filter)
        prefix = ENV['SCSB_S3_PARTNER_FULLS'] || 'data-exports/PUL/MARCXml/Full'
        @s3_bucket.download_recent(prefix:, output_directory: @update_directory, file_filter:)
      end
    end
  end
end
