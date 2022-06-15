class Alma::Indexer
  class DumpFileIndexer
    attr_reader :dump_file, :solr_url
    delegate :path, to: :dump_file
    delegate :index_file, to: :indexer
    def initialize(dump_file, solr_url:)
      @dump_file = dump_file
      @solr_url = solr_url
    end

    def index!
      decompress_file do |file|
        stdin, stdout, stderr = index_file(file.path)
        unless stderr.success? && !stdin.include?("FATAL")
          logger.error(stdin)
          raise "Traject indexing failed for #{file.path}"
        end
      end
    end

    def indexer
      @indexer ||= Alma::Indexer.new(solr_url: solr_url)
    end

    def decompress_file(&block)
      return tar_decompress_file(&block) if dump_file.path.include?(".tar")
      # SCSB files are only g-zipped.
      dump_file.unzip
      yield File.open(dump_file.path)
      dump_file.zip
    end

    # Alma files are tarred and g-zipped, so you have to do both.
    def tar_decompress_file
      tar_reader.each.map do |entry|
        Tempfile.create(decompressed_filename(entry), binmode: true) do |decompressed_tmp|
          decompressed_file = write_chunks(entry, decompressed_tmp)
          entry.close
          yield(decompressed_file)
        end
      end
    end

    def tar_reader
      tar_extract = Gem::Package::TarReader.new(Zlib::GzipReader.open(path))
      tar_extract.tap(&:rewind)
    end

    def write_chunks(entry, temp_file)
      while (chunk = entry.read(16 * 1024))
        temp_file.write chunk
      end
      temp_file.tap(&:rewind)
    end

    def decompressed_filename(entry)
      file_name, decompress_extension = entry.full_name.split(".")
      decompress_extension ||= "xml"
      ["full_reindex_file_unzip_#{file_name}", "." + decompress_extension]
    end
  end
end
