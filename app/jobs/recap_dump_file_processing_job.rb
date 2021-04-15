class RecapDumpFileProcessingJob < ActiveJob::Base
  def perform(dump_file)
    # Unzip/Parse dump file
    records = extract_records(dump_file.path)
    # For every record, build a fake AlmaItem/AlmaHolding
    # Create a MarcRecord for SCSB
    # Save the file.
    write_records(records, dump_file.path)
    # Transfer it to S3.
    RecapTransferJob.perform_later(dump_file)
  end

  # @param path [String] Path on disk to the records file.
  # @return Hash<String, Array<MARC::Record>> Hash of filenames to the
  #   MARC::Records that they represent.
  def extract_records(path)
    tar_extract = Gem::Package::TarReader.new(Zlib::GzipReader.open(path))
    tar_extract.tap(&:rewind)
    Hash[
      tar_extract.map do |tar_entry|
        content = StringIO.new(tar_entry.read)
        [tar_entry.header.name, MARC::XMLReader.new(content, external_encoding: 'UTF-8').to_a]
      end
    ]
  end

  # Persist the mutated records back to the file.
  # @param path [String] Path on disk to the records file.
  # @param records [Hash<String, Array<MARC::Record>>] Hash of filenames to the
  #   MARC::Records that they represent.
  def write_records(records, path)
    records_with_content = records.map do |filename, file_records|
      content = StringIO.new
      writer = MARC::XMLWriter.new(content)
      file_records.each do |record|
        writer.write(record)
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
end
