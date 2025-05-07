# frozen_string_literal: true

require 'rsolr'
require 'rexml/document'
require 'chronic'
require 'logger'
require 'json'
require 'iso-639'
require 'yaml'
require 'erb'
require 'ostruct'

module BibdataRs::Theses
  class Indexer
    SET = 'Princeton University Senior Theses'

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

    # @todo This needs to be refactored into a separate Class
    def self.config_file
      Rails.root.join('config/solr.yml')
    end

    def self.config_yaml
      ERB.new(IO.read(config_file)).result(binding)
    rescue StandardError, SyntaxError => e
      raise("#{config_file} was found, but could not be parsed with ERB. \n#{e.inspect}")
    end

    def self.config_values
      YAML.safe_load(config_yaml)
    end

    def self.env
      ENV['ORANGETHESES_ENV'] || 'development'
    end

    def self.config
      OpenStruct.new(solr: config_values[env])
    end

    def self.default_solr_url
      config.solr['url']
    end

    def initialize(solr_server = nil)
      solr_server ||= self.class.default_solr_url
      @solr = RSolr.connect(url: solr_server)
      @logger = Logger.new($stdout)
      @logger.level = Logger::INFO
      @logger.formatter = proc do |severity, datetime, _progname, msg|
        time = datetime.strftime('%H:%M:%S')
        "[#{time}] #{severity}: #{msg}\n"
      end
    end

    # @param element  A REXML::Element (because this is what we get from the OAI gem)
    # @return  The HTTP response status from Solr (??)
    def index(metadata_element)
      dc_elements = pull_dc_elements(metadata_element)
      doc = build_hash(dc_elements)
      @logger.info("Adding #{doc['id']}")
      @solr.add(doc, add_attributes: { commitWithin: 10 })
    rescue NoMethodError => e
      @logger.error(e.to_s)
      @logger.error(metadata_element)
    rescue StandardError => e
      @logger.error(e.to_s)
      dc_elements.each { |element| @logger.error(element.to_s) }
    end

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

    # @param doc [Hash] Metadata hash with dc and pu terms
    # @return  The HTTP response status from Solr (??)
    def index_document(**values)
      solr_doc = build_solr_document(**values)

      @logger.info("Adding #{solr_doc['id']}")
      @solr.add(solr_doc, add_attributes: { commitWithin: 10 })
    rescue NoMethodError => e
      @logger.error(e.to_s)
      @logger.error(doc.to_s)
    rescue StandardError => e
      @logger.error(e.to_s)
      @logger.error(doc.to_s)
    end

    private

    def build_hash(dc_elements)
      date = choose_date(dc_elements)
      h = {
        'id' => id(dc_elements),
        'title_t' => title(dc_elements),
        'title_citation_display' => title(dc_elements),
        'title_display' => title(dc_elements),
        'title_sort' => title_sort(dc_elements),
        'author_sort' => author_sort(dc_elements),
        'format' => 'Senior Thesis',
        'pub_date_display' => date,
        'pub_date_start_sort' => date,
        'pub_date_end_sort' => date,
        'class_year_s' => date,
        'access_facet' => 'Online',
        'electronic_access_1display' => ark(dc_elements),
        'standard_no_1display' => non_ark_ids(dc_elements),
        'electronic_portfolio_s' => online_holding({})

      }
      h.merge!(map_non_special_to_solr(dc_elements))
      h.merge!(HARD_CODED_TO_ADD)
      h
    end

    # @return Array<REXML::Element>  the descriptive elements
    def pull_dc_elements(element)
      element.elements.to_a('oai_dc:dc/*')
    end

    def choose_date(dc_elements)
      dates = all_date_elements(dc_elements).map { |d| Chronic.parse(d.text) }
      dates.empty? ? nil : dates.min.year
    end

    def all_date_elements(dc_elements)
      dc_elements.select { |e| e.name == 'date' }
    end

    def title(dc_elements)
      titles = dc_elements.select { |e| e.name == 'title' }
      titles.empty? ? nil : titles.first.text
    end

    def title_sort(dc_elements)
      titles = dc_elements.select { |e| e.name == 'title' }
      title = titles.empty? ? nil : titles.first.text
      title.downcase.gsub(/[^\p{Alnum}\s]/, '').gsub(/^(a|an|the)\s/, '').gsub(/\s/, '') unless title.nil?
    end

    def ark(dc_elements)
      arks = dc_elements.select do |e|
        e.name == 'identifier' && e.text.start_with?('http://arks.princeton')
      end
      arks.empty? ? nil : { arks.first.text => dspace_display_text(dc_elements) }.to_json.to_s
    end

    def online_holding(doc)
      {
        'thesis' => {
          'call_number' => call_number(doc['dc.identifier.other']),
          'call_number_browse' => call_number(doc['dc.identifier.other']),
          'dspace' => true
        }
      }.to_json.to_s
    end

    def physical_holding(doc, accessible: true)
      {
        'thesis' => {
          'location' => 'Mudd Manuscript Library',
          'library' => 'Mudd Manuscript Library',
          'location_code' => 'mudd$stacks',
          'call_number' => call_number(doc['dc.identifier.other']),
          'call_number_browse' => call_number(doc['dc.identifier.other']),
          'dspace' => accessible
        }
      }.to_json.to_s
    end

    def non_ark_ids(dc_elements)
      non_ark_ids = dc_elements.select do |e|
        e.name == 'identifier' && !e.text.start_with?('http://arks.princeton')
      end
      return { 'Other identifier' => non_ark_ids.map(&:text) }.to_json.to_s unless non_ark_ids.empty?

      nil
    end

    def id(dc_elements)
      arks = dc_elements.select do |e|
        e.name == 'identifier' && e.text.start_with?('http://arks.princeton')
      end
      arks.empty? ? nil : arks.first.text.split('/').last
    end

    def author_sort(dc_elements)
      authors = dc_elements.select { |e| e.name == 'creator' }
      authors.empty? ? nil : authors.first.text
    end

    def choose_date_hash(doc)
      dates = all_date_elements_hash(doc).map { |_k, v| Chronic.parse(v.first) }.compact
      dates.empty? ? nil : dates.min.year
    end

    def all_date_elements_hash(doc)
      doc.select { |k, _v| k[/dc\.date/] }
    end

    def title_sort_hash(titles)
      titles.first.downcase.gsub(/[^\p{Alnum}\s]/, '').gsub(/^(a|an|the)\s/, '').gsub(/\s/, '') unless titles.nil?
    end

    # Take first title, strip out latex expressions when present to include along
    # with non-normalized version (allowing users to get matches both when LaTex
    # is pasted directly into the search box and when sub/superscripts are placed
    # adjacent to regular characters
    def title_search_hash(titles)
      return if titles.nil?

      title = BibdataRs::Theses::normalize_latex titles.first
      title == titles.first ? title : [titles.first, title]
    end

    def ark_hash(doc)
      arks = doc['dc.identifier.uri']
      arks.nil? ? nil : { arks.first => dspace_display_text_hash(doc) }.to_json.to_s
    end

    def call_number(non_ark_ids)
      non_ark_ids.nil? ? 'AC102' : "AC102 #{non_ark_ids.first}"
    end

    def first_or_nil(field)
      field&.first
    end

    def dspace_display_text(dc_elements)
      text = [dataspace]
      text << if dc_elements.select { |e| e.name == 'rights' }.empty?
                full_text
              else
                citation
              end
      text
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
      output = false

      has_location = doc.key?('pu.location')
      output ||= has_location

      has_rights = doc.key?('pu.rights.accessRights')
      output ||= has_rights

      output ||= walkin?(doc)

      if output
        values = doc.fetch('pu.date.classyear', [])
        output = if !values.empty?

                   classyear = values.first
                   # For theses, there is no physical copy since 2013
                   # anything 2012 and prior have a physical copy
                   # @see https://github.com/pulibrary/orangetheses/issues/76
                   classyear.to_i < 2013
                 else
                   false
                 end
      end
      output ||= embargo?(doc)
      output
    end

    def embargo?(doc)
      date = doc['pu.embargo.lift'] || doc['pu.embargo.terms']
      return false if date.nil?

      date = Chronic.parse(date.first)
      if date.nil?
        @logger.info("No valid embargo date for #{doc['id']}")
        return false
      end

      date > Time.now
    end

    def embargo(doc)
      date = doc['pu.embargo.lift'] || doc['pu.embargo.terms']
      date = Chronic.parse(date.first) unless date.nil?
      date = date.strftime('%B %-d, %Y') unless date.nil?
      date
    end

    def walkin?(doc)
      walkin = doc['pu.mudd.walkin']
      !walkin.nil? && walkin.first == 'yes'
    end

    def build_embargo_text(doc)
      embargo_date = embargo(doc)
      doc_id = doc['id']
      "This content is embargoed until #{embargo_date}. For more information contact the "\
      "<a href=\"mailto:dspadmin@princeton.edu?subject=Regarding embargoed DataSpace Item 88435/#{doc_id}\"> "\
      'Mudd Manuscript Library</a>.'
    end

    def walkin_text
      'Walk-in Access. This thesis can only be viewed on computer terminals at the '\
      '<a href=\"http://mudd.princeton.edu\">Mudd Manuscript Library</a>.'
    end

    def restrictions_display_text(doc)
      if embargo?(doc)
        output = build_embargo_text(doc)

        return output
      end

      if walkin?(doc)
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

    # this is kind of a mess...
    def map_non_special_to_solr(dc_elements)
      h = {}
      NON_SPECIAL_ELEMENT_MAPPING.each do |element_name, fields|
        elements = dc_elements.select { |e| e.name == element_name }
        fields.each do |f|
          if h.key?(f)
            h[f].push(*elements.map(&:text))
          else
            h[f] = elements.map(&:text)
          end
        end
      end
      h
    end

    # default English
    def code_to_language(codes)
      languages = []
      # en_US is not valid iso code
      codes&.each do |c|
        code_lang = ISO_639.find(c[/^[^_]*/]) # en_US is not valid iso code
        l = code_lang.nil? ? 'English' : code_lang.english_name
        languages << l
      end
      languages.empty? ? 'English' : languages.uniq
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
      h = {}
      if doc.key?('pu.date.classyear') && doc['pu.date.classyear'].first =~ /^\d+$/
        h['class_year_s'] = doc['pu.date.classyear']
        h['pub_date_start_sort'] = doc['pu.date.classyear']
        h['pub_date_end_sort'] = doc['pu.date.classyear']
      end
      h
    end

    # online access when there isn't a restriction/location note
    def holdings_access(doc)
      # This handles cases for items in the Mudd Library
      doc_embargoed = embargo?(doc)
      doc_on_site_only = on_site_only?(doc)

      if doc_embargoed
        {
          'location' => 'Mudd Manuscript Library',
          'location_display' => 'Mudd Manuscript Library',
          'location_code_s' => 'mudd$stacks',
          'advanced_location_s' => ['mudd$stacks', 'Mudd Manuscript Library'],
          'access_facet' => nil,
          'holdings_1display' => nil,
          'advanced_location_s' => ['mudd$stacks', 'Mudd Manuscript Library']
        }
      elsif doc_on_site_only
        {
          'location' => 'Mudd Manuscript Library',
          'location_display' => 'Mudd Manuscript Library',
          'location_code_s' => 'mudd$stacks',
          'advanced_location_s' => ['mudd$stacks', 'Mudd Manuscript Library'],
          'access_facet' => 'In the Library',
          'holdings_1display' => physical_holding(doc)
        }

      else
        {
          'access_facet' => 'Online',
          'electronic_portfolio_s' => online_holding(doc)
        }
      end
    end
  end
end
