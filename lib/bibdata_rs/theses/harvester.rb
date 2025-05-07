# frozen_string_literal: true

require 'oai'
require 'tmpdir'

module BibdataRs::Theses
  class Harvester
    def self.default_server
      return 'https://dataspace-staging.princeton.edu/oai/request' if test?

      'https://dataspace.princeton.edu/oai/request'
    end

    def self.default_metadata_prefix
      'oai_dc'
    end

    def self.default_verb
      'ListRecords'
    end

    def self.default_set
      'com_88435_dsp019c67wm88m'
    end

    # @param [Hash] opts  options to pass to the client
    # @option opts [String] :dir  Directory in which to save files. A temporary
    #   directory will be created if this option is not included.
    # @option opts [String] :server ('http://dataspace.princeton.edu/oai/')
    # @option opts [String] :metadata_prefix ('oai_dc')
    # @option opts [String] :verb ('ListRecords')
    # @option opts [String] :set ('hdl_88435_dsp019c67wm88m')
    def initialize(dir: Dir.mktmpdir,
                   server: nil,
                   metadata_prefix: nil,
                   verb: nil,
                   set: nil)

      @dir = dir
      @server = server || self.class.default_server
      @metadata_prefix = metadata_prefix || self.class.default_metadata_prefix
      @verb = verb || self.class.default_verb
      @set = set || self.class.default_set
    end

    # @return [Array<String>] A list of directories containing metadata records
    def harvest_all
      dirs = []
      dir = nil
      client.list_records(headers).full.each_with_index do |record, i|
        if (i % 1000).zero?
          dir = Dir.mktmpdir(nil, @dir)
          dirs << dir
        end
        File.write(File.join(dir, "#{i}.xml"), record.metadata)
      end
      dirs
    end

    # Index all records into the Solr Collection
    def index_all(indexer)
      client.list_records(headers).full.each_with_index do |record, _i|
        indexer.index(record.metadata)
      rescue StandardError => e
        Rails.logger.warn("Error indexing the OAI-PMH record #{record.metadata}: #{e}")
      end
    end

    def index_item(indexer:, identifier:)
      record_response = client.get_record(identifier:)
      record = record_response.record

      indexer.index(record.metadata)
    rescue StandardError => e
      Rails.logger.warn("Error indexing the OAI-PMH record using #{identifier}: #{e}")
    end

    private

      def headers
        {
          metadataPrefix: @metadata_prefix,
          set: @set
        }
      end

      def client
        @client ||= OAI::Client.new(@server)
      end
  end
end
