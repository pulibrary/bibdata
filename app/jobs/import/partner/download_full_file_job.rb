module Import
  module Partner
    class DownloadFullFileJob
      include Sidekiq::Job
      def perform(dump_id, institution, file_prefix)
        zip_file = Scsb::PartnerUpdates::Full.download_full_file(institution, 'zip')

        raise StandardError("No full dump files found matching #{institution}") unless zip_file

        xml_files = unzip_file(zip_file, file_prefix)
        xml_files = xml_files.to_set
        batch.jobs do
          process_xml_files_batch = Sidekiq::Batch.new
          process_xml_files_batch.description = "Process #{xml_files.size} unzipped xml files from #{institution}"
          process_xml_files_batch.on(:success, 'Import::Partner::FullCallbacks#process_xml_file_success', 'zip_file' => zip_file)
          process_xml_files_batch.jobs do
            xml_files.each do |file|
              Import::Partner::ProcessXmlFileJob.perform_async(dump_id, file)
            end
          end
        end
      end

      def unzip_file(file, file_prefix)
        update_directory = ENV.fetch('SCSB_PARTNER_UPDATE_DIRECTORY', '/tmp/updates')
        xml_files = []
        filename = File.basename(file, '.zip')
        filename.gsub!(/^[^_]+_([0-9]+)_([0-9]+).*$/, '\1_\2')
        file_increment = 1
        Zip::File.open(file) do |zip_file|
          zip_file.each do |entry|
            target = "#{update_directory}/#{file_prefix}#{filename}_#{file_increment}.xml"
            xml_files << target
            entry.extract(target)
            file_increment += 1
          # If the file already exists, we probably partially ran this job previously, and it's not a problem.
          # Should just move to the next entry.
          rescue Zip::DestinationFileExistsError => e
            Rails.logger.info(e.message)
          end
        end
        xml_files
      end
    end
  end
end
