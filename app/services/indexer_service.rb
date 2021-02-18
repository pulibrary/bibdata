# Allows to process a MARC record through Traject
# as a class without having to invoke Traject from
# the command line and without having to push it
# to Solr.
#
# indexer = IndexerService.new
# hash = indexer.map_record(<MARC record goes here>)
#
class IndexerService
  def self.build
    new.build
  end

  def build
    indexer.load_config_file(traject_config_file_path.to_s)
    indexer
  end

  def indexer
    @indexer ||= Traject::Indexer.new
  end

  def traject_config_file_path
    Rails.root.join('marc_to_solr', 'lib', 'traject_config.rb')
  end
end
