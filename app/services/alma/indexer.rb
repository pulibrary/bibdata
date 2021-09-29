require 'rubygems/package'
class Alma::Indexer
  attr_reader :solr_url
  def initialize(solr_url:)
    @solr_url = solr_url
  end

  def index_file(file_name, debug_mode = false)
    debug_flag = debug_mode ? "--debug-mode" : ""
    `traject #{debug_flag} -c marc_to_solr/lib/traject_config.rb #{file_name} -u #{solr_url} -w Traject::PulSolrJsonWriter 2>&1`
  end
end
