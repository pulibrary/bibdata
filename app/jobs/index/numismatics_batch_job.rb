module Index
  class NumismaticsBatchJob
    include Sidekiq::Worker

    def perform(solr_url, solr_docs)
      indexer = NumismaticsIndexer.new(solr_connection: RSolr.connect(url: solr_url), progressbar: false, logger: Rails.logger)
      indexer.index_in_chunks(solr_docs)
    end
  end
end
