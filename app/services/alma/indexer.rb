module Alma
  class Indexer
    attr_reader :solr_url

    def initialize(solr_url:)
      @solr_url = solr_url
    end

    def index_file(file_path, flags = '')
      # nosemgrep
      stdout, stderr, status = Open3.capture3("RUBY_YJIT_ENABLE=yes traject #{flags} -c marc_to_solr/lib/traject_config.rb #{file_path} -u #{solr_url} -w Traject::PulSolrJsonWriter")
      if stderr.include?('FATAL') && !status.success?
        Rails.logger.error(stderr)
        raise "Traject indexing failed for #{file_path}: #{stderr}"
      else
        Rails.logger.info("Successfully indexed file #{file_path}")
      end
    end

    def index_file_debug(file_path, flags = '')
      index_file file_path, "--debug-mode #{flags}"
    end
  end
end
