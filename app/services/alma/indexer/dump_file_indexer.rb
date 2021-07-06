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
      dump_file.update(index_status: :started)
      decompress_file do |file|
        index_file(file.path)
      end
      dump_file.update(index_status: :done)
    end

    def indexer
      @indexer ||= Alma::Indexer.new(solr_url: solr_url)
    end

    def decompress_file
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
