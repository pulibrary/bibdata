class DumpFileIndexJob < ActiveJob::Base
  def perform(dump_file, solr_url:)
    Alma::Indexer::DumpFileIndexer.new(dump_file, solr_url: solr_url).index!
  end
end
