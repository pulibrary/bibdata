module Import
  module Partner
    class ProcessXmlFileJob
      include Sidekiq::Job

      def perform(dump_id, file)
        scsb_file_dir = ENV.fetch('SCSB_FILE_DIR')
        filename = File.basename(file)
        reader = MARC::XMLReader.new(file.to_s, parser: :nokogiri)
        file_path = "#{scsb_file_dir}/#{filename}"
        writer = MARC::XMLWriter.new(file_path)
        reader.map { |record| writer.write(Scsb::PartnerUpdates::Full.process_record(record)) }
        writer.close
        Dump.attach_dump_file(dump_id, file_path, :recap_records_full)
        FileUtils.rm_f(file)
      end
    end
  end
end
