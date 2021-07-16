# Processes boundwith records from SCSB dump files coming from Alma and updates the
# DumpFile for submission to the S3 Bucket.
class RecapBoundwithsProcessingJob < RecapDumpFileProcessingJob
  attr_reader :dump
  def perform(dump)
    @dump = dump

    # Extract boundwith from all dump files, process, and save in temp file
    process_boundwiths
    return unless boundwith_records.present?
    # Transfer it to S3.
    return tempfile.path if RecapTransferService.transfer(file_path: tempfile.path)
    raise(StandardError, "Error uploading file to S3: #{tempfile.path}")
  end

  private

    def process_boundwiths
      # Cache boundwith records from dump files
      boundwith_records.each(&:cache)
      # Save processed boundwith records in the dump file
      write_records("boundwiths" => find_related)
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

    # Find related host and constituent records and add
    # to set of boundwith records.
    # @return [Array<AlmaAdapter::ScsbDumpRecord>]
    def find_related
      cache_miss_ids = []
      # Group marc records by host record id
      grouped_records = boundwith_records.group_by do |r|
        r.constituent? ? r.host_id : r.id
      end

      # Iterate through each key in grouped_records
      grouped_records.each do |host_id, records|
        host_record = records.find(&:host?)
        constituent_records = records.find_all(&:constituent?)

        unless host_record
          begin
            # Get host record id from a constituent[773w] and
            # retrieve from Alma or cache
            host_record = constituent_records.first.host_record
            # Add missing host record to group
            grouped_records[host_id] << host_record
          rescue AlmaAdapter::ScsbDumpRecord::CacheMiss => e
            # Store mmsids of records missing from the cache
            cache_miss_ids << e.message
            next
          end
        end

        # Fetch constituent record ids from host[774w] and retrieve from Alma or
        # cache; skipping any constituents already in the dump file
        begin
          skip_ids = constituent_records.map { |r| r.marc_record["001"].value }
          missing_constituents = host_record.constituent_records(skip_ids: skip_ids)
          # Add missing constituent records to group
          grouped_records[host_id] << missing_constituents
        rescue AlmaAdapter::ScsbDumpRecord::CacheMiss => e
          cache_miss_ids << e.message
        end
      end
      # If the cache is missing records, raise an exception that lists all the ids
      raise(AlmaAdapter::ScsbDumpRecord::CacheMiss, cache_error_message(cache_miss_ids)) unless cache_miss_ids.empty?

      grouped_records.values.flatten.compact
    end

    def cache_error_message(ids)
      "Records not found in the cache. Create a set of the missing " \
        "records in Alma, publish using the DRDS ReCAP Records publishing " \
        "profile, and load into the cache using the `cache_file` rake task." \
        "Missing mmsids: #{ids.join(',')}"
    end

    # Generate boundwith dump file name using
    # existing dump file name as a template.
    # @return [String]
    def boundwiths_file_name
      basename = File.basename(dump.dump_files.first.path)
      basename.gsub(/new_[0-9]*/, 'boundwiths')
    end

    def tempfile
      @tempfile ||= begin
        basename = File.basename(boundwiths_file_name).split(".")
        extensions = "." + basename[1..-1].join(".")
        Tempfile.new([basename[0], extensions])
      end
    end
end
