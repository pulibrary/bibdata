module Import
  module Partner
    class DownloadFullFileJob
      include Sidekiq::Job
      def perform(dump_id, institution, prefix)
        zip_file = Scsb::PartnerUpdates::Full.download_full_file(institution, 'zip')

        raise StandardError("No full dump files found matching #{institution}") unless zip_file

        xml_files = unzip_file(zip_file)
        batch.jobs do
          process_xml_files_batch = Sidekiq::Batch.new
          process_xml_files_batch.description = "Process #{xml_files.size} unzipped xml files from #{institution}"
          process_xml_files_batch.on(:success, 'Import::Partner::FullCallbacks#process_xml_file_success')
          process_xml_files_batch.jobs do
            file_prefix = prefix
            scsb_file_dir = ENV.fetch('SCSB_FILE_DIR')
            xml_files.each do |file|
              filename = File.basename(file)
              reader = MARC::XMLReader.new(file.to_s, external_encoding: 'UTF-8')
              file_path = "#{scsb_file_dir}/#{file_prefix}#{filename}"
              writer = MARC::XMLWriter.new(file_path)
              reader.each { |record| writer.write(Scsb::PartnerUpdates::Full.process_record(record)) }
              writer.close
              File.unlink(file)
              Dump.attach_dump_file(dump_id, file_path, :recap_records_full)
            end
          end
        end
      end

      def unzip_file(file)
        update_directory = ENV.fetch('SCSB_PARTNER_UPDATE_DIRECTORY', '/tmp/updates')
        xml_files = []
        filename = File.basename(file, '.zip')
        filename.gsub!(/^[^_]+_([0-9]+)_([0-9]+).*$/, '\1_\2')
        file_increment = 1
        Zip::File.open(file) do |zip_file|
          zip_file.each do |entry|
            target = "#{update_directory}/#{filename}_#{file_increment}.xml"
            xml_files << target
            entry.extract(target)
            file_increment += 1
          end
        end
        File.unlink(file)
        xml_files
      end
    end
  end
end
