require 'rubygems/package'
class Alma::Indexer
  attr_reader :solr_url
  def initialize(solr_url:)
    @solr_url = solr_url
  end

  # Index the file to solr using traject and return
  # @param file_name [String]
  # @param debug_mode [Boolean]
  # @return [Array]
  def index_file(file_name, debug_mode = false)
    debug_flag = debug_mode ? "--debug-mode" : ""
    cmd = "traject #{debug_flag} -c marc_to_solr/lib/traject_config.rb #{file_name} -u #{solr_url} -w Traject::PulSolrJsonWriter"
    stdin, stdout, stderr = Open3.capture3(cmd)
    [stdin, stdout, stderr]
  end
end
