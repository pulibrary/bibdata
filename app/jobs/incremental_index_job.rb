class IncrementalIndexJob < ActiveJob::Base
  queue_as :default

  def perform(dump)
    solr_config = Rails.application.config.solr
    indexer = Alma::Indexer.new(solr_config['url'])
    indexer.incremental_index!(dump)
  end
end
