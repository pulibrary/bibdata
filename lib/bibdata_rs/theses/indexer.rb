# frozen_string_literal: true

require 'chronic'
require 'logger'
require 'json'


module BibdataRs::Theses
  class Indexer
    NON_SPECIAL_ELEMENT_MAPPING = {
      'creator' => %w[author_display author_s],
      'contributor' => %w[advisor_display author_s],
      'format' => ['description_display'],
      'rights' => ['rights_reproductions_note_display'],
      'description' => ['summary_note_display']
    }.freeze

    REST_NON_SPECIAL_ELEMENT_MAPPING = {
      'dc.contributor.author' => %w[author_display author_s],
      'dc.contributor.advisor' => %w[advisor_display author_s],
      'dc.contributor' => %w[contributor_display author_s],
      'pu.department' => %w[department_display author_s],
      'pu.certificate' => %w[certificate_display author_s],
      'dc.format.extent' => ['description_display'],
      'dc.description.abstract' => ['summary_note_display']
    }.freeze

    HARD_CODED_TO_ADD = {
      'format' => 'Senior thesis'
    }.freeze


    # Constructs DataspaceDocument objects from a Hash of attributes
    # @returns [DataspaceDocument]
    def build_solr_document(**values)
      id = values['id']

      title = values['dc.title']
      title_t = title_search_hash(title)
      title_citation_display = first_or_nil(title)
      title_display = title_citation_display
      title_sort = title_sort_hash(title)

      author = values['dc.contributor.author']
      author_sort = first_or_nil(author)

      electronic_access_1display = ark_hash(values)

      identifier_other = values['dc.identifier.other']
      call_number_display = call_number(identifier_other)
      call_number_browse_s = call_number_display

      language_iso = values['dc.language.iso']
      language_facet = code_to_language(language_iso)
      language_name_display = language_facet

      attrs = {
        'id' => id,
        'title_t' => title_t,
        'title_citation_display' => title_citation_display,
        'title_display' => title_display,
        'title_sort' => title_sort,
        'author_sort' => author_sort,
        'electronic_access_1display' => electronic_access_1display,
        'restrictions_note_display' => restrictions_display_text(values),
        'call_number_display' => call_number_display,
        'call_number_browse_s' => call_number_browse_s,
        'language_facet' => language_facet,
        'language_name_display' => language_name_display
      }
      mapped = map_rest_non_special_to_solr(values)
      attrs.merge!(mapped)

      class_years = class_year_fields(values)
      attrs.merge!(class_years)

      holdings = holdings_access(values)
      attrs.merge!(holdings)

      attrs.merge!(HARD_CODED_TO_ADD)

      DataspaceDocument.new(document: attrs, logger: @logger)
    end


    private


      def title_sort_hash(titles)
        titles.first.downcase.gsub(/[^\p{Alnum}\s]/, '').gsub(/^(a|an|the)\s/, '').gsub(/\s/, '') unless titles.nil?
      end

      # Take first title, strip out latex expressions when present to include along
      # with non-normalized version (allowing users to get matches both when LaTex
      # is pasted directly into the search box and when sub/superscripts are placed
      # adjacent to regular characters
      def title_search_hash(titles)
        return if titles.nil?

        title = BibdataRs::Theses.normalize_latex titles.first
        title == titles.first ? title : [titles.first, title]
      end

      def ark_hash(doc)
        arks = doc['dc.identifier.uri']
        arks.nil? ? nil : { arks.first => dspace_display_text_hash(doc) }.to_json.to_s
      end

      def call_number(non_ark_ids)
        BibdataRs::Theses::call_number non_ark_ids
      end

      def first_or_nil(field)
        field&.first
      end

      def dspace_display_text_hash(doc)
        text = [dataspace]
        text << if on_site_only?(doc)
                  citation
                else
                  full_text
                end
        text
      end

      def on_site_only?(doc)
        BibdataRs::Theses::on_site_only(
          doc.key?('pu.location'),
          doc.key?('pu.rights.accessRights'),
          doc['pu.mudd.walkin'],
          doc.fetch('pu.date.classyear', []),
          doc['pu.embargo.lift'],
          doc['pu.embargo.terms']
        )
      end

      def walkin_text
        'Walk-in Access. This thesis can only be viewed on computer terminals at the '\
          '<a href=\"http://mudd.princeton.edu\">Mudd Manuscript Library</a>.'
      end

      def restrictions_display_text(doc)
        if BibdataRs::Theses::has_current_embargo(doc['pu.embargo.lift'], doc['pu.embargo.terms'])
          return BibdataRs::Theses.embargo_text(doc['pu.embargo.lift'], doc['pu.embargo.terms'], doc['id'])
        end

        if BibdataRs::Theses.looks_like_yes(doc['pu.mudd.walkin'])
          output = walkin_text

          return output
        end

        fields = []
        if doc.key?('pu.location')
          field = doc['pu.location']
          fields << field
        end

        if doc.key?('dc.rights.accessRights')
          field = doc['pu.rights.accessRights']
          fields << field
        end

        flattened = fields.flatten
        flattened.compact
      end

      def dataspace
        'DataSpace'
      end

      def full_text
        'Full text'
      end

      def citation
        'Citation only'
      end

      # default English
      def code_to_language(codes)
        BibdataRs::Theses::codes_to_english_names(codes)
      end

      def map_rest_non_special_to_solr(doc)
        h = {}
        REST_NON_SPECIAL_ELEMENT_MAPPING.each do |field_name, solr_fields|
          next unless doc.key?(field_name)

          solr_fields.each do |f|
            val = []
            val << h[f]
            val << doc[field_name]
            h[f] = val.flatten.compact
            # Ruby might have a bug here
            # if h.has_key?(f)
            #   h[f].push(doc[field_name])
            # else
            #   h[f] = doc[field_name]
            # end
          end
        end
        h
      end

      def class_year_fields(doc)
        JSON.parse BibdataRs::Theses.class_year_fields(doc['pu.date.classyear'])
      end

      # online access when there isn't a restriction/location note
      def holdings_access(doc)
        JSON.parse BibdataRs::Theses.holding_access_string(
          doc.key?('pu.location'),
          doc.key?('pu.rights.accessRights'),
          doc['pu.mudd.walkin'],
          doc.fetch('pu.date.classyear', []),
          doc['pu.embargo.lift'],
          doc['pu.embargo.terms'],
          doc['dc.identifier.other']
        )
      end
  end
end
