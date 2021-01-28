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
