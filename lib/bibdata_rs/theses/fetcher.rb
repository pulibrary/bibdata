# frozen_string_literal: true

require 'faraday'
require 'json'
require 'tmpdir'
require 'openssl'
require 'retriable'
require 'logger'
require 'yaml'
require 'erb'

# Do not fail if SSL negotiation with DSpace isn't working
OpenSSL::SSL::VERIFY_PEER = OpenSSL::SSL::VERIFY_NONE

module BibdataRs::Theses
  class Fetcher
    attr_writer :logger

    def self.config_file_path
      Rails.root.join('config/dspace.yml')
    end

    def self.config_file
      IO.read(config_file_path)
    end

    def self.config_erb
      ERB.new(config_file).result(binding)
    rescue StandardError, SyntaxError => e
      raise("#{config_file} was found, but could not be parsed with ERB. \n#{e.inspect}")
    end

    def self.config_yaml
      YAML.safe_load(config_erb, aliases: true)
    end

    def self.env
      ENV['RAILS_ENV'] || 'development'
    end

    def self.env_config
      config_yaml[env]
    end

    def self.default_server
      env_config['server']
    end

    def self.default_community
      env_config['community']
    end

    def self.default_rest_limit
      env_config['rest_limit']
    end

    # @param [Hash] opts  options to pass to the client
    # @option opts [String] :server ('https://dataspace.princeton.edu/rest/')
    # @option opts [String] :community ('88435/dsp019c67wm88m')
    def initialize(server: nil, community: nil, rest_limit: nil)
      @server = server || self.class.default_server
      @community = community || self.class.default_community

      @rest_limit = rest_limit || self.class.default_rest_limit
    end

    def logger
      @logger ||= begin
        built = Logger.new($stdout)
        built.level = Logger::DEBUG
        built
      end
    end

    ##
    # Where files get cached for later indexing
    def json_file_path
      @json_file_path ||= ENV['FILEPATH'] || '/tmp/theses.json'
    end

    ##
    # Write to the log anytime an API call fails and we have to retry.
    # See https://github.com/kamui/retriable#callbacks for more information.
    def log_retries
      proc do |exception, try, elapsed_time, next_interval|
        logger.debug "#{exception.class}: '#{exception.message}' - #{try} tries in #{elapsed_time} seconds and #{next_interval} seconds until the next try."
      end
    end

    ##
    # @param id [String] thesis collection id
    # @return [Array<Hash>] metadata hash for each record
    def fetch_collection(id)
      theses = []
      offset = 0
      completed = false

      until completed
        url = build_collection_url(id:, offset:)
        logger.debug("Querying for the DSpace Collection at #{url}...")
        Retriable.retriable(on: JSON::ParserError, tries: Orangetheses::RETRY_LIMIT, on_retry: log_retries) do
          response = api_client.get(url)
          items = JSON.parse(response.body)
          if items.empty?
            completed = true
          else
            theses << flatten_json(items)
            offset += @rest_limit
          end
        end
      end
      theses.flatten
    end

    def index_collection(indexer, id)
      fetched = fetch_collection(id)
      fetched.each do |record|
        indexer.index_hash(record)
      end
    end

    def index_all_collections(indexer)
      collections.each do |c|
        index_collection(indexer, c)
      end
    end

    ##
    # Cache all collections
    def cache_all_collections(indexer)
      solr_documents = []

      collections.each do |collection_id|
        collection_documents = cache_collection(indexer, collection_id)
        solr_documents += collection_documents
      end

      solr_documents.flatten
    end

    ##
    # Cache a single collection
    def cache_collection(indexer, collection_id)
      solr_documents = []

      elements = fetch_collection(collection_id)
      elements.each do |attrs|
        solr_document = indexer.build_solr_document(**attrs)
        solr_documents << solr_document
      end

      solr_documents
    end

    ##
    # Get a json representation of a single collection and write it as JSON to
    # a cache file.
    def self.write_collection_to_cache(collection_id)
      indexer = Indexer.new
      fetcher = Fetcher.new
      File.open(fetcher.json_file_path, 'w') do |f|
        documents = fetcher.cache_collection(indexer, collection_id)
        solr_documents = documents.map(&:to_solr)
        json_cache = JSON.pretty_generate(solr_documents)
        f.puts(json_cache)
      end
    end

    ##
    # Get a json representation of all thesis collections and write it as JSON to
    # a cache file.
    def self.write_all_collections_to_cache
      indexer = Indexer.new
      fetcher = Fetcher.new
      File.open(fetcher.json_file_path, 'w') do |f|
        documents = fetcher.cache_all_collections(indexer)
        solr_documents = documents.map(&:to_solr)
        json_cache = JSON.pretty_generate(solr_documents)
        f.puts(json_cache)
      end
    end

    ##
    # The DSpace id of the community we're fetching content for.
    # E.g., for handle '88435/dsp019c67wm88m', the DSpace id is 267
    def api_community_id
      @api_community_id ||= api_community['id'].to_s
    end

    private

    def build_collection_url(id:, offset:)
      "#{@server}/collections/#{id}/items?limit=#{@rest_limit}&offset=#{offset}&expand=metadata"
    end

    def flatten_json(items)
      items.collect do |i|
        h = {}
        h['id'] = i['handle'][%r{[^/]*$}]
        i['metadata'].each do |m|
          m['value'] = map_department(m['value']) if m['key'] == 'pu.department'
          m['value'] = map_program(m['value']) if m['key'] == 'pu.certificate'
          next if m['value'].nil?

          if h[m['key']].nil?
            h[m['key']] = [m['value']]
          else
            h[m['key']] << m['value']
          end
        end
        h
      end
    end

    def api_client
      Faraday
    end

    def api_communities
      @api_communities ||= begin
        response = api_client.get("#{@server}/communities/")
        response.body
      rescue StandardError => e
        Faraday.logger.warn(e)
        '[]'
      end
    end

    def json_api_communities
      @json_api_communities ||= JSON.parse(api_communities)
    end

    ##
    # Parse the JSON feed containing all of the communities, and return only the
    # community that matches the handle.
    # @return [JSON] a json representation of the DSpace community
    def api_community
      return if json_api_communities.empty?

      @api_community ||= json_api_communities.find { |c| c['handle'] == @community }
    end

    ##
    # Get all of the collections for a given community
    def api_collections
      @api_collections ||= begin
        collections_url = "#{@server}/communities/#{api_community_id}/collections"
        logger.info("Querying #{collections_url} for the collections...")
        response = api_client.get(collections_url)
        response.body
      end
    end

    ##
    # All of the collections for a given community, parsed as JSON
    def api_collections_json
      @api_collections_json ||= JSON.parse(api_collections)
    end

    # example to debug using a specific collection id.
    # @collections ||= api_collections_json.map { |i| i['id'] = '2666' }
    # https://dataspace-dev.princeton.edu/rest/collections/2666/items
    def collections
      @collections ||= api_collections_json.map { |i| i['id'] }
    end

    def map_department(dept)
      lc_authorized_departments[dept]
    end

    def map_program(program)
      BibdataRs::Theses::map_program program
    end

    def lc_authorized_departments
      {
        'African American Studies' => 'Princeton University. Department of African American Studies',
        'Art and Archaeology' => 'Princeton University. Department of Art and Archaeology',
        'Aeronautical Engineering' => 'Princeton University. Department of Aeronautical Engineering',
        'Anthropology' => 'Princeton University. Department of Anthropology',
        'Architecture School' => 'Princeton University. School of Architecture',
        'Astrophysical Sciences' => 'Princeton University. Department of Astrophysical Sciences',
        'Biochemical Sciences' => 'Princeton University. Department of Biochemical Sciences',
        'Biology' => 'Princeton University. Department of Biology',
        'Civil and Environmental Engineering' => 'Princeton University. Department of Civil and Environmental Engineering',
        'Civil Engineering and Operations Research' => 'Princeton University. Department of Civil Engineering and Operations Research',
        'Chemical and Biological Engineering' => 'Princeton University. Department of Chemical and Biological Engineering',
        'Chemistry' => 'Princeton University. Department of Chemistry',
        'Classics' => 'Princeton University. Department of Classics',
        'Comparative Literature' => 'Princeton University. Department of Comparative Literature',
        'Computer Science' => 'Princeton University. Department of Computer Science',
        'East Asian Studies' => 'Princeton University. Department of East Asian Studies',
        'Economics' => 'Princeton University. Department of Economics',
        'Ecology and Evolutionary Biology' => 'Princeton University. Department of Ecology and Evolutionary Biology',
        'Electrical Engineering' => 'Princeton University. Department of Electrical Engineering',
        'Engineering and Applied Science' => 'Princeton University. School of Engineering and Applied Science',
        'English' => 'Princeton University. Department of English',
        'French and Italian' => 'Princeton University. Department of French and Italian',
        'Geosciences' => 'Princeton University. Department of Geosciences',
        'German' => 'Princeton University. Department of Germanic Languages and Literatures',
        'History' => 'Princeton University. Department of History',
        'Special Program in Humanities' => 'Princeton University. Special Program in the Humanities',
        'Independent Concentration' => 'Princeton University Independent Concentration Program',
        'Mathematics' => 'Princeton University. Department of Mathematics',
        'Molecular Biology' => 'Princeton University. Department of Molecular Biology',
        'Mechanical and Aerospace Engineering' => 'Princeton University. Department of Mechanical and Aerospace Engineering',
        'Medieval Studies' => 'Princeton University. Program in Medieval Studies',
        'Modern Languages' => 'Princeton University. Department of Modern Languages.',
        'Music' => 'Princeton University. Department of Music',
        'Near Eastern Studies' => 'Princeton University. Department of Near Eastern Studies',
        'Neuroscience' => 'Princeton Neuroscience Institute',
        'Operations Research and Financial Engineering' => 'Princeton University. Department of Operations Research and Financial Engineering',
        'Oriental Studies' => 'Princeton University. Department of Oriental Studies',
        'Philosophy' => 'Princeton University. Department of Philosophy',
        'Physics' => 'Princeton University. Department of Physics',
        'Politics' => 'Princeton University. Department of Politics',
        'Psychology' => 'Princeton University. Department of Psychology',
        'Religion' => 'Princeton University. Department of Religion',
        'Romance Languages and Literatures' => 'Princeton University. Department of Romance Languages and Literatures',
        'Slavic Languages and Literature' => 'Princeton University. Department of Slavic Languages and Literatures',
        'Sociology' => 'Princeton University. Department of Sociology',
        'Spanish and Portuguese' => 'Princeton University. Department of Spanish and Portuguese Languages and Cultures',
        'Spanish and Portuguese Languages and Cultures' => 'Princeton University. Department of Spanish and Portuguese Languages and Cultures',
        'Statistics' => 'Princeton University. Department of Statistics',
        'School of Public and International Affairs' => 'School of Public and International Affairs'
      }
    end
  end
end
