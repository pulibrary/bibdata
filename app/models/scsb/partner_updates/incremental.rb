module Scsb
  class PartnerUpdates
    class Incremental < Update
      def process_incremental_files
        prepare_directory
        update_files = download_partner_updates
        process_partner_updates(files: update_files)
        set_generated_date
        log_record_fixes
        delete_files = download_partner_deletes
        process_partner_deletes(files: delete_files)
      end

      def download_partner_updates
        file_list = @s3_bucket.list_files(prefix: ENV.fetch('SCSB_S3_PARTNER_UPDATES', nil) || 'data-exports/PUL/MARCXml/Incremental')
        @s3_bucket.download_files(files: file_list, timestamp_filter: @last_dump, output_directory: @update_directory)
      end

      def download_partner_deletes
        file_list = @s3_bucket.list_files(prefix: ENV.fetch('SCSB_S3_PARTNER_DELETES', nil) || 'data-exports/PUL/Json')
        @s3_bucket.download_files(files: file_list, timestamp_filter: @last_dump, output_directory: @update_directory)
      end

      def process_partner_deletes(files:)
        json_files = []
        files.each do |file|
          filename = File.basename(file, '.zip')
          file_increment = 1
          Zip::File.open(file) do |zip_file|
            zip_file.each do |entry|
              target = "#{@update_directory}/scsbdelete#{filename}_#{file_increment}.json"
              json_files << target
              entry.extract(target)
              file_increment += 1
            end
          end
          File.unlink(file)
        end
        ids = []
        json_files.each do |file|
          scsb_ids(file, ids)
          File.unlink(file)
        end
        @dump.delete_ids = ids
        @dump.save
      end

      def scsb_ids(filename, ids)
        file = File.read(filename)
        data = JSON.parse(file)
        data.each do |record|
          ids << "SCSB-#{record['bib']['bibId']}"
        end
        ids
      end
    end
  end
end
