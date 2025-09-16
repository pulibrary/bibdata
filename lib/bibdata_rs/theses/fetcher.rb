# frozen_string_literal: true

module BibdataRs
  module Theses
    class Fetcher
      def self.env_config
        Rails.application.config_for Rails.root.join('config/dspace.yml')
      end

      def self.default_server
        env_config['server']
      end

      def self.default_community
        env_config['community']
      end

      def self.default_legacy_server
        env_config['legacy_server']
      end

      def self.default_legacy_community
        env_config['legacy_community']
      end

      def self.default_rest_limit
        env_config['rest_limit']
      end

      ##
      # Get a json representation of all thesis collections and write it as JSON to
      # a cache file.
      def self.write_all_collections_to_cache
        BibdataRs::Theses.all_documents_as_solr(default_legacy_server, default_legacy_community, default_rest_limit)
        BibdataRs::Theses.all_documents_as_solr(default_server, default_community, default_rest_limit)
      end
    end
  end
end
