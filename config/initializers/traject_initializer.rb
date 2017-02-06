
def setup_indexer
  c = File.join(Rails.root, 'marc_to_solr', 'lib', 'traject_config.rb')
  indexer = Traject::Indexer.new
  indexer.load_config_file(c)
  indexer
end

TRAJECT_INDEXER ||= setup_indexer
