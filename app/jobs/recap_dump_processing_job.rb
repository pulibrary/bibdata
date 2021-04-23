# Checks the whole dump for boundwiths before processing each dumpfile
class RecapDumpProcessingJob < ActiveJob::Base
  def perform(dump)
    dump.dump_files.each do |dump_file|
      RecapDumpFileProcessingJob.perform_later(dump_file)
    end

    process_bound_withs(dump)
  end

  private

    # add a new dump file that's just all the boundwiths
    def process_bound_withs(dump)
      boundwiths_dump_file = DumpFile.create(dump_file_type: dump_file_type)

      boundwith_records = dump.dump_files.map do |dump_file|
        extract_boundwiths(dump_file.path).values
      end.flatten.compact

      # Find related records and retrieve from Alma
      boundwith_records = find_related(boundwith_records)

      # TODO: Give our boundwith file a better filename. Strip everything after
      # the [] of the timestamp and use the front of one of the other filenames.

      write_boundwith_file({ "boundwiths" => boundwith_records }, boundwiths_dump_file.path)
      dump.dump_files << boundwiths_dump_file
    end

    def dump_file_type
      DumpFileType.find_by(constant: "RECAP_RECORDS")
    end

    # @param path [String] Path on disk to the records file.
    # @return Hash<String, Array<MARC::Record>> Hash of filenames to the
    #   MARC::Records that they represent.
    def extract_boundwiths(path)
      tar_extract = Gem::Package::TarReader.new(Zlib::GzipReader.open(path))
      tar_extract.tap(&:rewind)
      Hash[
        tar_extract.map do |tar_entry|
          content = StringIO.new(tar_entry.read)
          records = MARC::XMLReader.new(content, external_encoding: 'UTF-8').to_a.map do |record|
            # ScsbDumpRecord will handle converting from the dump's MARC-XML to
            # the proper format for submitCollection
            scsb_record = AlmaAdapter::ScsbDumpRecord.new(marc_record: record)
            next unless scsb_record.boundwith?
            scsb_record
          end
          [tar_entry.header.name, records]
        end
      ]
    end

    # Persist the mutated records back to the file.
    # @param path [String] Path on disk to the records file.
    # @param records [Hash<String, Array<AlmaAdapter::ScsbDumpRecord>>] Hash of filenames to the
    #   MARC::Records that they represent.
    def write_boundwith_file(records, path)
      records_with_content = records.map do |filename, file_records|
        content = StringIO.new
        writer = MARC::XMLWriter.new(content)
        file_records.each do |record|
          writer.write(record.transformed_record)
        end
        writer.close
        [filename, content.string]
      end
      archive_path(path, records_with_content)
    end

    def archive_path(path, records_with_content)
      File.open(path, "wb") do |file|
        Zlib::GzipWriter.wrap(file) do |gzip|
          Gem::Package::TarWriter.new(gzip) do |tar|
            records_with_content.each do |filename, content|
              tar.add_file_simple(filename, 0o644, content.bytesize) do |io|
                io.write(content)
              end
            end
          end
        end
      end
    end

    # @return [Array<AlmaAdapter::ScsbDumpRecord>]
    def find_related(marc_records)
      # Cache updated records
      marc_records.each(&:cache)

      # Group marc records by host record id
      grouped_records = marc_records.group_by do |r|
        r.constituent? ? r.host_id : r.id
      end

      # Iterate through each key in grouped_records
      grouped_records.each do |host_id, records|
        host_record = records.find(&:host?)
        constituent_records = records.find_all(&:constituent?)
        # Does grouping have a host record?
        if host_record
          # Fetch constituent record ids from host[774] and retrieve from Alma;
          # skipping any constituents already in the dump file
          skip_ids = constituent_records.map { |r| r.marc_record["001"].value }
          missing_constituents = host_record.constituent_records(skip_ids: skip_ids)
        elsif constituent_records.present?
          # Get host record id from a constituent[773] and retreive from Alma
          host_record = constituent_records.first.host_record
          if host_record
            # Fetch constituent record ids from host[774] and retrieve from Alma;
            # skipping any constituents already in the dump file
            skip_ids = constituent_records.map { |r| r.marc_record["001"].value }
            missing_constituents = host_record.constituent_records(skip_ids: skip_ids)
            # Add missing host record to group
            grouped_records[host_id] << host_record
          end
        end

        # Add missing constituent records to group
        grouped_records[host_id] << missing_constituents
      end

      grouped_records.values.flatten.compact
    end
end
