require 'json'

module Scsb
  class PartnerUpdates
    extend ActiveSupport::Concern

    def initialize(dump:, timestamp:)
      @dump = dump
      @s3_bucket = Scsb::S3Bucket.new
      @update_directory = ENV['SCSB_PARTNER_UPDATE_DIRECTORY'] || '/tmp/updates'
      @scsb_file_dir = ENV['SCSB_FILE_DIR'] || 'data'
      @last_dump = timestamp.to_time
      @inv_xml = []
      @tab_newline = []
      @leader = []
      @composed_chars = []
      @bad_utf8 = []
    end

    def process_partner_files
      get_partner_updates
      process_partner_updates
      log_record_fixes
      get_partner_deletes
      process_partner_deletes
    end

    private

      def get_partner_updates
        prepare_directory
        file_list = @s3_bucket.list_files(prefix: ENV['SCSB_S3_PARTNER_UPDATES'] || 'data-exports/PUL/MARCXml/')
        @s3_bucket.download_files(files: file_list, timestamp_filter: @last_dump, output_directory: @update_directory)
      end

      def get_partner_deletes
        prepare_directory
        file_list = @s3_bucket.list_files(prefix: ENV['SCSB_S3_PARTNER_DELETES'] || 'data-exports/PUL/Json/Incremental')
        @s3_bucket.download_files(files: file_list, timestamp_filter: @last_dump, output_directory: @update_directory)
      end

      def process_partner_deletes
        files = Dir.glob("#{@update_directory}/*.zip")
        files.each do |file|
          filename = File.basename(file, '.zip')
          file_increment = 1
          Zip::File.open(file) do |zip_file|
            zip_file.each do |entry|
              target = "#{@update_directory}/scsbdelete#{filename}_#{file_increment}.json"
              entry.extract(target)
              file_increment += 1
            end
          end
          File.unlink(file)
        end
        files = Dir.glob("#{@update_directory}/*.json")
        ids = []
        files.each do |file|
          filename = File.basename(file, '.json')
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

      def process_partner_updates
        files = Dir.glob("#{@update_directory}/*.zip")
        files.each do |file|
          filename = File.basename(file, '.zip')
          filename.gsub!(/^[^_]+_([0-9]+)_([0-9]+).*$/, '\1_\2')
          file_increment = 1
          Zip::File.open(file) do |zip_file|
            zip_file.each do |entry|
              target = "#{@update_directory}/#{filename}_#{file_increment}.xml"
              entry.extract(target)
              file_increment += 1
            end
          end
          File.unlink(file)
        end
        filepaths = []
        Dir.glob("#{@update_directory}/*.xml").each do |file|
          filename = File.basename(file)
          reader = MARC::XMLReader.new(file.to_s, external_encoding: 'UTF-8')
          filepath = "#{@scsb_file_dir}/scsbupdate#{filename}"
          writer = MARC::XMLWriter.new(filepath)
          reader.each { |record| writer.write(process_record(record)) }
          writer.close
          filepaths << filepath
          File.unlink(file)
        end
        filepaths.sort.each { |f| attach_dump_file(f) }
      end

      def process_record(record)
        record = field_delete(['856', '959'], record)
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

      def attach_dump_file(filepath, constant = 'RECAP_RECORDS')
        dump_file_type = DumpFileType.find_by(constant: constant)
        df = DumpFile.create(dump_file_type: dump_file_type, path: filepath)
        df.zip
        df.save
        @dump.dump_files << df
        @dump.save
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
        attach_dump_file(filepath, 'LOG_FILE')
      end

      def log_file_name
        "#{@scsb_file_dir}/fixes_#{@last_dump.strftime('%Y_%m_%d')}.json"
      end

      def prepare_directory
        if File.exist?(@update_directory)
          Dir.glob("#{@update_directory}/*").each { |file| File.delete(file) }
        else
          Dir.mkdir(@update_directory)
        end
      end
  end
end
