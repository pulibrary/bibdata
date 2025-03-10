module Index
  class NumismaticsJob
    include Sidekiq::Worker

    def perform(solr_url = IndexManager.rebuild_solr_url, chunk_size = 500)
      batch = Sidekiq::Batch.new
      batch.description = 'Numismatics indexing batch'
      batch.jobs do
        NumismaticsIndexer.new(
          solr_connection: RSolr.connect(url: solr_url),
          progressbar: false,
          logger: Rails.logger
        ).solr_documents.each_slice(chunk_size) do |docs|
          NumismaticsBatchJob.perform_async(solr_url, docs)
        end
      end
    end
  end
end
