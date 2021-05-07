# Processes boundwith records from SCSB dump files coming from Alma and updates the
# DumpFile for submission to the S3 Bucket.
class RecapBoundwithsProcessingJob < RecapDumpFileProcessingJob
  attr_reader :dump
  def perform(dump)
    @dump = dump

    # Extract boundwith from all dump files, process, and create new dump file
    dump_file = process_boundwiths

    # Add new dump file that's just all the boundwiths
    dump.dump_files << dump_file
    dump.save

    # Transfer it to S3.
    RecapTransferJob.perform_later(dump_file)
  end

  private

    # @return [DumpFile]
    def process_boundwiths
      # Create a new dump file to store boundwiths
      boundwiths_dump_file = DumpFile.create(dump_file_type: dump_file_type)

      # Rename dump file
      boundwiths_dump_file.path = transform_file_name(boundwiths_dump_file.path, dump.dump_files.first.path)

      # Cache boundwith records from dump files
      boundwith_records.each(&:cache)

      # Save processed boundwith records in the dump file
      write_records({ "boundwiths" => find_related }, boundwiths_dump_file.path)

      boundwiths_dump_file
    end

    # Extract boundwith records from dumpfiles
    # @return [Array<AlmaAdapter::ScsbDumpRecord>]
    def boundwith_records
      @boundwith_records ||= dump.dump_files.map do |dump_file|
        extract_records(dump_file.path) do |scsb_record|
          # Skip record if it is not a boundwith
          next unless scsb_record.boundwith?
          scsb_record
        end.values
      end.flatten.compact
    end

    # @return [DumpFileType]
    def dump_file_type
      DumpFileType.find_by(constant: "RECAP_RECORDS")
    end

    # Find related host and constiuent records and add
    # to set of boundwith records.
    # @return [Array<AlmaAdapter::ScsbDumpRecord>]
    def find_related
      # Group marc records by host record id
      grouped_records = boundwith_records.group_by do |r|
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

    # Rename boundwith dump file default name using
    # existing dump file name as a template.
    # @return [String]
    def transform_file_name(path, template_path)
      basename = File.basename(template_path)
      basepath = File.dirname(path)
      File.join(basepath, basename.gsub(/new_[0-9]*/, 'boundwiths'))
    end
end
