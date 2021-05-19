# Processes an incremental dump file for SCSB coming from Alma and updates the
# DumpFile for submission to the S3 Bucket.
class RecapDumpFileProcessingJob < ActiveJob::Base
  attr_reader :dump_file
  def perform(dump_file)
    @dump_file = dump_file

    # Unzip/Parse dump file
    records = extract_records(dump_file.path) do |scsb_record|
      # Skip record if it's a boundwith
      next if scsb_record.boundwith?
      scsb_record
    end
    # Save the file.
    write_records(records)
    # Transfer it to S3.
    return tempfile.path if RecapTransferService.transfer(file_path: tempfile.path)
    raise(StandardError, "Error uploading file to S3: #{tempfile.path}")
  end

  private

    # @param path [String] Path on disk to the records file.
    # @yieldparam [MARC::Record] scsb record
    # @return Hash<String, Array<MARC::Record>> Hash of filenames to the
    #   MARC::Records that they represent.
    def extract_records(path)
      tar_extract = Gem::Package::TarReader.new(Zlib::GzipReader.open(path))
      tar_extract.tap(&:rewind)
      Hash[
        tar_extract.map do |tar_entry|
          content = StringIO.new(tar_entry.read)
          records = MARC::XMLReader.new(content, external_encoding: 'UTF-8').to_a.map do |record|
            # ScsbDumpRecord will handle converting from the dump's MARC-XML to
            # the proper format for submitCollection
            scsb_record = AlmaAdapter::ScsbDumpRecord.new(marc_record: record)

            # Caller determines whether to skip or return the record
            yield scsb_record
          end.compact
          [tar_entry.header.name, records]
        end
      ]
    end

    # Persist the mutated records back to the file.
    # @param path [String] Path on disk to the records file.
    # @param records [Hash<String, Array<AlmaAdapter::ScsbDumpRecord>>] Hash of filenames to the
    #   MARC::Records that they represent.
    def write_records(records)
      records_with_content = records.map do |filename, file_records|
        content = StringIO.new
        writer = MARC::XMLWriter.new(content)
        file_records.each do |record|
          writer.write(record.transformed_record)
        end
        writer.close
        [filename, content.string]
      end
      archive_path(records_with_content)
    end

    def tempfile
      @tempfile ||= begin
        basename = File.basename(dump_file.path).split(".")
        extensions = "." + basename[1..-1].join(".")
        Tempfile.new([basename[0], extensions])
      end
    end

    def archive_path(records_with_content)
      File.open(tempfile, "wb") do |file|
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
end
