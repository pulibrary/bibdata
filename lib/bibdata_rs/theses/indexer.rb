# frozen_string_literal: true

require 'logger'
require 'json'

module BibdataRs::Theses
  class Indexer

    # Constructs DataspaceDocument objects from a Hash of attributes
    # @returns [DataspaceDocument]
    def build_solr_document(**values)
      attrs = JSON.parse BibdataRs::Theses.ruby_json_to_solr_json(values.to_json)
      DataspaceDocument.new(document: attrs, logger: @logger)
    end
  end
end
