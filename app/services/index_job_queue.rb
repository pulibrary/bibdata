
# Service Class for reindexing MARC records
class IndexJobQueue
  # Generates the path to the Traject executable
  # @return [String] the path
  def self.traject_path
    '/usr/bin/env traject'
  end

  # Generates the settings arguments used for autocommitting after the index
  # @return [String]
  def self.traject_commit_settings
    values = ['--setting', 'solrj_writer.commit_on_close=true']
    values.join(' ')
  end

  # Constructor
  # @param config [String] path to the Traject configuration
  # @param url [String] URL to the Solr core
  # @param commit [TrueClass, FalseClass] whether or not to commit after the POST request has been made
  def initialize(config:, url:, commit: true)
    @config = config
    @url = url
    @commit = commit
  end

  # Index a file
  # @param file [String] path to the MARC XML file being indexed
  def add(file:)
    commit = @commit ? self.class.traject_commit_settings : ''
    IndexJob.perform_later(traject: self.class.traject_path, config: @config, file: file, url: @url, commit: commit)
  end
end
