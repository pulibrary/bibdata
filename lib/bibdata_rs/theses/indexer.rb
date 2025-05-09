# frozen_string_literal: true

require 'chronic'
require 'logger'
require 'json'


module BibdataRs::Theses
  class Indexer

    # Constructs DataspaceDocument objects from a Hash of attributes
    # @returns [DataspaceDocument]
    def build_solr_document(**values)
      attrs = JSON.parse BibdataRs::Theses.ruby_json_to_solr_json(values.to_json)
      attrs.merge!(JSON.parse BibdataRs::Theses.non_special_fields(
        values['dc.contributor.author'],
        values['dc.contributor.advisor'],
        values['dc.contributor'],
        values['pu.department'],
        values['pu.certificate'],
        values['dc.format.extent'],
        values['dc.description.abstract']
      )){|key, oldval, newval| oldval unless oldval.nil? }

      attrs.merge!(JSON.parse BibdataRs::Theses.class_year_fields(values['pu.date.classyear'])){|key, oldval, newval| oldval unless oldval.nil?}
      attrs.merge!(JSON.parse BibdataRs::Theses.holding_access_string(
        values.key?('pu.location'),
        values.key?('pu.rights.accessRights'),
        values['pu.mudd.walkin'],
        values.fetch('pu.date.classyear', []),
        values['pu.embargo.lift'],
        values['pu.embargo.terms'],
        values['dc.identifier.other']
      )){|key, oldval, newval| oldval unless oldval.nil?}

      DataspaceDocument.new(document: attrs, logger: @logger)
    end


    private


      def title_sort_hash(titles)
        titles.first.downcase.gsub(/[^\p{Alnum}\s]/, '').gsub(/^(a|an|the)\s/, '').gsub(/\s/, '') unless titles.nil?
      end

      def title_search_hash(titles)
        BibdataRs::Theses.title_search_versions titles
      end

      def ark_hash(doc)
        BibdataRs::Theses.ark_hash(doc['dc.identifier.uri'], doc.key?('pu.location'),
          doc.key?('pu.rights.accessRights'),
          doc['pu.mudd.walkin'],
          doc.fetch('pu.date.classyear', []),
          doc['pu.embargo.lift'],
          doc['pu.embargo.terms'])
      end

      def call_number(non_ark_ids)
        BibdataRs::Theses::call_number non_ark_ids
      end

      def first_or_nil(field)
        field&.first
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


      # default English
      def code_to_language(codes)
        BibdataRs::Theses::codes_to_english_names(codes)
      end

      def class_year_fields(doc)
        JSON.parse BibdataRs::Theses.class_year_fields(doc['pu.date.classyear'])
      end
  end
end
