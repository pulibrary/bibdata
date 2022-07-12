class Alma::Indexer
  class DumpFileIndexer
    attr_reader :dump_file, :solr_url
    delegate :index_file, to: :indexer
    def initialize(dump_file, solr_url:)
      @dump_file = dump_file
      @solr_url = solr_url
    end

    def index!
      decompress_file do |file|
        result = index_file(file.path)
        raise "Traject indexing failed for #{file.path}" unless $CHILD_STATUS.success? && !result.include?("FATAL")
      end
    end

    def indexer
      @indexer ||= Alma::Indexer.new(solr_url: solr_url)
    end

    def decompress_file(&block)
      return dump_file.tar_decompress_file(&block) if dump_file.path.include?(".tar")
      # SCSB files are only g-zipped.
      dump_file.unzip
      yield File.open(dump_file.path)
      dump_file.zip
    end
  end
end
