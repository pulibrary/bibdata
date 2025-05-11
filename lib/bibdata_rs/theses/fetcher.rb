# frozen_string_literal: true

require 'faraday'
require 'json'
require 'tmpdir'
require 'openssl'
require 'retriable'
require 'logger'

# Do not fail if SSL negotiation with DSpace isn't working
OpenSSL::SSL::VERIFY_PEER = OpenSSL::SSL::VERIFY_NONE

module BibdataRs::Theses
  class Fetcher
    attr_writer :logger

    # leave in Ruby, since the Rails thing is so convenient
    def self.env_config
      Rails.application.config_for Rails.root.join('config/dspace.yml'), env: BibdataRs::Theses.rails_env
    end

    # leave in Ruby (if needed), since the config file is tricky in rust since it contains a variety of data types
    def self.default_server
      env_config['server']
    end

    # leave in Ruby (if needed), since the config file is tricky in rust since it contains a variety of data types
    def self.default_community
      env_config['community']
    end

    # leave in Ruby (if needed), since the config file is tricky in rust since it contains a variety of data types
    def self.default_rest_limit
      env_config['rest_limit']
    end

    # @param [Hash] opts  options to pass to the client
    # @option opts [String] :server ('https://dataspace.princeton.edu/rest/')
    # @option opts [String] :community ('88435/dsp019c67wm88m')
    # leave in ruby for now
    def initialize(server: nil, community: nil, rest_limit: nil)
      @server = server || self.class.default_server
      @community = community || self.class.default_community

      @rest_limit = rest_limit || self.class.default_rest_limit
    end

    # leave in ruby for now
    # USED
    def logger
      @logger ||= begin
        built = Logger.new($stdout)
        built.level = Logger::DEBUG
        built
      end
    end

    ##
    # Write to the log anytime an API call fails and we have to retry.
    # See https://github.com/kamui/retriable#callbacks for more information.
    # leave in ruby right now, since I'm not sure how to return a proc in Magnus
    # USED
    def log_retries
      proc do |exception, try, elapsed_time, next_interval|
        logger.debug "#{exception.class}: '#{exception.message}' - #{try} tries in #{elapsed_time} seconds and #{next_interval} seconds until the next try."
      end
    end

    ##
    # @param id [String] thesis collection id
    # @return [Array<Hash>] metadata hash for each record
    # Rewrite in Rust, but rewrite flatten_json first?  Or does it make sense to do them separately???
    # USED
    def fetch_collection(id)
      theses = []
      offset = 0
      completed = false

      until completed
        url = BibdataRs::Theses.collection_url(@server, id.to_s, @rest_limit.to_s, offset.to_s)
        logger.debug("Querying for the DSpace Collection at #{url}...")
        Retriable.retriable(on: JSON::ParserError, tries: Orangetheses::RETRY_LIMIT, on_retry: log_retries) do
          response = api_client.get(url)
          items = JSON.parse(response.body)

          if items.empty?
            completed = true
          else
            theses << items
            offset += @rest_limit
          end
        end
      end
      theses.flatten
    end

    ##
    # Cache all collections
    # USED
    def cache_all_collections
      solr_documents = []

      collections.each do |collection_id|
        collection_documents = cache_collection(collection_id)
        solr_documents += collection_documents
      end

      solr_documents.flatten
    end

    ##
    # Cache a single collection
    # USED
    def cache_collection(collection_id)
      solr_documents = []

      elements = fetch_collection(collection_id)
      elements.each do |attrs|
        solr_document = JSON.parse(BibdataRs::Theses.ruby_json_to_solr_json(attrs.to_json))
        solr_documents << solr_document
      end

      solr_documents
    end

    ##
    # Get a json representation of all thesis collections and write it as JSON to
    # a cache file.
    # USED
    def self.write_all_collections_to_cache
      # fetcher = Fetcher.new
      # File.open(BibdataRs::Theses.theses_cache_path, 'w') do |f|
        BibdataRs::Theses.all_documents_as_solr(default_server, default_community, default_rest_limit)
        # solr_documents = fetcher.cache_all_collections
        # json_cache = JSON.pretty_generate(solr_documents)
        # f.puts(json_cache)
      # end
    end

    private

      # USED
      def api_client
        Faraday
      end

      def collections
        BibdataRs::Theses.collection_ids(@server, @community)
      end
  end
end
