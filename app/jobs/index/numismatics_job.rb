module Index
  class NumismaticsJob
    include Sidekiq::Worker

    def perform(solr_url = IndexManager.rebuild_solr_url, chunk_size = 500)
      batch = Sidekiq::Batch.new
      batch.description = 'Numismatics indexing batch'
      batch.on(:success, NumismaticsJob, solr_url:)
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

    def on_success(_status, options)
      solr_connection = RSolr.connect(url: options['solr_url'])
      # soft commit to avoid timeouts
      solr_connection.commit(commit_attributes: { waitSearcher: false })
    end
  end
end
