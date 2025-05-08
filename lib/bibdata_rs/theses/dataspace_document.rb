# frozen_string_literal: true

require 'chronic'

module BibdataRs::Theses
  # Class modeling the behavior for Solr Documents generated with DataSpace Item
  #   metadata
  class DataspaceDocument
    attr_reader :document

    def initialize(document:, logger:)
      @document = document
      @logger = logger
    end

    delegate :key?, to: :document

    delegate :[], to: :document

    def id
      document['id']
    end

    def embargo_present?
      BibdataRs::Theses.has_embargo_date(document['pu.embargo.lift'], document['pu.embargo.terms'])
    end

    def embargo_valid?
      BibdataRs::Theses.has_parseable_embargo_date(document['pu.embargo.lift'], document['pu.embargo.terms'])
    end

    def embargo_active?
      BibdataRs::Theses.has_current_embargo(document['pu.embargo.lift'], document['pu.embargo.terms'])
    end

    def location
      @location ||= document['pu.location']
    end

    def access_rights
      @access_rights ||= document['dc.rights.accessRights']
    end

    def restrictions_access
      values = [
        location,
        access_rights
      ]
      flattened = values.flatten
      flattened.compact
    end

    def walkin?
      BibdataRs::Theses.looks_like_yes document['pu.mudd.walkin']
    end

    def to_solr
      values = document.dup
      values['restrictions_note_display'] = restrictions_note_display
      values
    end

    private

      def walkin_restrictions
        "Walk-in Access. This thesis can only be viewed on computer terminals at the '<a href=\"http://mudd.princeton.edu\">Mudd Manuscript Library</a>."
      end

      # rubocop:disable Layout/LineLength
      def invalid_embargo_restrictions_note
        "This content is currently under embargo. For more information contact the <a href=\"mailto:dspadmin@princeton.edu?subject=Regarding embargoed DataSpace Item 88435/#{id}\"> Mudd Manuscript Library</a>."
      end
      # rubocop:enable Layout/LineLength

      # rubocop:disable Layout/LineLength
      def embargo_restrictions_note
        BibdataRs::Theses.embargo_text(document['pu.embargo.lift'], document['pu.embargo.terms'], id)
      end
      # rubocop:enable Layout/LineLength

      def restrictions_note_display
        if location || access_rights
          restrictions_access
        elsif walkin?
          walkin_restrictions
        elsif embargo_present?
          if !embargo_valid?
            logger.warn("Failed to parse the embargo date for #{id}")
            invalid_embargo_restrictions_note
          elsif embargo_active?
            embargo_restrictions_note
          end
        end
      end
  end
end
