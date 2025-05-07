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

    def key?(value)
      document.key?(value)
    end

    def [](value)
      document[value]
    end

    def id
      document['id']
    end

    def embargo_lift_field
      return unless document.key?('pu.embargo.lift')

      @embargo_lift_field ||= document['pu.embargo.lift']
    end

    def embargo_terms_field
      return unless document.key?('pu.embargo.terms')

      @embargo_terms_field ||= document['pu.embargo.terms']
    end

    def embargo_date_fields
      @embargo_date_fields ||= embargo_lift_field || embargo_terms_field
    end

    def embargo_date_field
      return if embargo_date_fields.nil?

      embargo_date_fields.first
    end

    def embargo_date
      return if embargo_date_field.nil?

      @embargo_date ||= Chronic.parse(embargo_date_field)
    end

    def embargo_present?
      !embargo_date_field.nil?
    end

    def formatted_embargo_date
      return if embargo_date.nil?

      @formatted_embargo_date ||= embargo_date.strftime('%B %-d, %Y')
    end

    def embargo_valid?
      return false unless embargo_present?

      !embargo_date.nil?
    end

    def embargo_active?
      return false unless embargo_valid?

      embargo_date > Time.now
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

    def walkin
      @walkin ||= document['pu.mudd.walkin']
    end

    def walkin?
      !walkin.nil? && walkin.first == 'yes'
    end

    def to_solr
      values = document.dup
      values['restrictions_note_display'] = restrictions_note_display
      values
    end

    private

    # rubocop:disable Layout/LineLength
    def walkin_restrictions
      "Walk-in Access. This thesis can only be viewed on computer terminals at the '<a href=\"http://mudd.princeton.edu\">Mudd Manuscript Library</a>."
    end
    # rubocop:enable Layout/LineLength

    # rubocop:disable Layout/LineLength
    def invalid_embargo_restrictions_note
      "This content is currently under embargo. For more information contact the <a href=\"mailto:dspadmin@princeton.edu?subject=Regarding embargoed DataSpace Item 88435/#{id}\"> Mudd Manuscript Library</a>."
    end
    # rubocop:enable Layout/LineLength

    # rubocop:disable Layout/LineLength
    def embargo_restrictions_note
      "This content is embargoed until #{formatted_embargo_date}. For more information contact the <a href=\"mailto:dspadmin@princeton.edu?subject=Regarding embargoed DataSpace Item 88435/#{id}\"> Mudd Manuscript Library</a>."
    end
    # rubocop:enable Layout/LineLength

    # rubocop:disable Metrics/MethodLength
    # rubocop:disable Metrics/PerceivedComplexity
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
    # rubocop:enable Metrics/MethodLength
    # rubocop:enable Metrics/PerceivedComplexity
  end
end
