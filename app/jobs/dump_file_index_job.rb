class DumpFileIndexJob
  include Sidekiq::Worker
  def perform(dump_file_id, solr_url)
    dump_file = DumpFile.find(dump_file_id)
    Alma::Indexer::DumpFileIndexer.new(dump_file, solr_url:).index!
  end
end
