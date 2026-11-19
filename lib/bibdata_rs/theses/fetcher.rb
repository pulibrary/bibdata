# frozen_string_literal: true

module BibdataRs
  module Theses
    module Fetcher
      extend self

      ##
      # Get a json representation of all thesis collections and write it as JSON to
      # a cache file.
      def write_all_collections_to_cache
        BibdataRs::Theses.all_legacy_documents_as_solr(default_legacy_server, default_community, default_rest_limit)
        BibdataRs::Theses.all_documents_as_solr(default_server, default_community, default_rest_limit)
        merge_theses_json
      end

      private

        def env_config
          Rails.application.config_for Rails.root.join('config/dspace.yml')
        end

        def default_server
          env_config['server']
        end

        def default_community
          env_config['community']
        end

        def default_legacy_server
          env_config['legacy_server']
        end

        def default_rest_limit
          env_config['rest_limit']
        end

        def theses_cache_path
          env_config['filepath'] || '/tmp/theses.json'
        end

        def temp_theses_cache_path
          env_config['temp_filepath'] || '/tmp/temp_theses.json'
        end

        def temp_legacy_theses_cache_path
          env_config['temp_legacy_filepath'] || '/tmp/temp_legacy_theses.json'
        end

        def merge_theses_json
          theses_json = File.read(temp_theses_cache_path)
          legacy_theses_json = File.read(temp_legacy_theses_cache_path)

          parsed_theses = JSON.parse(theses_json)
          parsed_legacy_theses = JSON.parse(legacy_theses_json)

          merged_theses = parsed_theses + parsed_legacy_theses
          File.write(theses_cache_path, JSON.pretty_generate(merged_theses))
        end
    end
  end
end
