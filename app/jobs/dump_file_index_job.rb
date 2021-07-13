class DumpFileIndexJob < ActiveJob::Base
  def perform(dump_file, solr_url:)
    ActiveRecord::Base.connection_pool.with_connection do
      Alma::Indexer::DumpFileIndexer.new(dump_file, solr_url: solr_url).index!
    end
  end
end
