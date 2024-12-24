module Scsb
  class PartnerUpdates
    class Update
      attr_accessor :dump

      def initialize(dump:, dump_file_type:, timestamp:)
        @last_dump = timestamp
        @dump = dump
        @dump_file_type = dump_file_type
        @s3_bucket = Scsb::S3Bucket.partner_transfer_client
        @scsb_file_dir = ENV['SCSB_FILE_DIR']
        @update_directory = ENV['SCSB_PARTNER_UPDATE_DIRECTORY'] || '/tmp/updates'
        @inv_xml = []
        @tab_newline = []
        @leader = []
        @composed_chars = []
        @bad_utf8 = []
      end

      def attach_dump_file(filepath, dump_file_type: nil)
        dump_file_type ||= @dump_file_type
        df = DumpFile.create(dump_file_type:, path: filepath)
        df.zip
        df.save
        @dump.dump_files << df
        @dump.save
      end

      def process_partner_updates(files:, file_prefix: 'scsb_update_')
        xml_files = []
        files.each do |file|
          filename = File.basename(file, '.zip')
          filename.gsub!(/^[^_]+_([0-9]+)_([0-9]+).*$/, '\1_\2')
          file_increment = 1
          Zip::File.open(file) do |zip_file|
            zip_file.each do |entry|
              target = "#{@update_directory}/#{filename}_#{file_increment}.xml"
              xml_files << target
              entry.extract(target)
              file_increment += 1
            end
          end
          File.unlink(file)
        end
        xml_files.each do |file|
          filename = File.basename(file)
          reader = MARC::XMLReader.new(file.to_s, external_encoding: 'UTF-8')
          filepath = "#{@scsb_file_dir}/#{file_prefix}#{filename}"
          writer = MARC::XMLWriter.new(filepath)
          reader.each { |record| writer.write(process_record(record)) }
          writer.close
          File.unlink(file)
          attach_dump_file(filepath)
        end
      end

      def process_record(record)
        record = field_delete(['856', '959'], record)
        record.leader[5] = 'c' if record.leader[5].eql?('d')
        if bad_utf8?(record)
          @bad_utf8 << record['001']
          record = bad_utf8_fix(record)
        end
        if invalid_xml_chars?(record)
          @inv_xml << record['001']
          record = invalid_xml_fix(record)
        end
        if tab_newline_char?(record)
          @tab_newline << record['001']
          record = tab_newline_fix(record)
        end
        if leader_errors?(record)
          @leader << record['001']
          record = leaderfix(record)
        end
        if composed_chars_errors?(record)
          @composed_chars << record['001']
          record = composed_chars_normalize(record)
        end
        record = extra_space_fix(record)
        empty_subfield_fix(record)
      end

      def add_error(message:)
        error = Array.wrap(@dump.event.error)
        error << message
        @dump.event.error = error.join('; ')
        @dump.event.save
      end

      def log_record_fixes
        log_file = {
          inv_xml: @inv_xml,
          tab_newline: @tab_newline,
          leader: @leader,
          composed_chars: @composed_chars,
          bad_utf8: @bad_utf8
        }
        filepath = log_file_name
        File.write(filepath, log_file.to_json.to_s)
        attach_dump_file(filepath, dump_file_type: :log_file)
      end

      def log_file_name
        "#{@scsb_file_dir}/fixes_#{@last_dump.to_time.strftime('%Y_%m_%d')}.json"
      end

      def set_generated_date
        @dump.generated_date = date_strings.map { |str| DateTime.parse(str) }.sort.first
      end

      def date_strings
        @dump.dump_files.map do |df|
          if df.dump_file_type == 'recap_records_full_metadata'
            File.basename(df.path).split('_')[3]
          else
            File.basename(df.path).split('_')[2]
          end
        end
      end

      def prepare_directory
        FileUtils.mkdir_p(@update_directory)
      end
    end
  end
end
