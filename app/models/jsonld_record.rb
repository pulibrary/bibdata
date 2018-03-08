# Class for JSON-LD graphs encoding bibliographic records
class JSONLDRecord
  # Constructor
  # @param solr_doc [Hash] SolrDocument serialized as a Hash
  def initialize(solr_doc = {})
    @solr_doc = solr_doc
  end

  # Generate a Hash from the graph values
  # @return [Hash]
  def to_h
    metadata = {}
    metadata[:title] = title if title
    metadata[:language] = iso_codes unless iso_codes.empty?

    metadata_map.each do |solr_key, metadata_key|
      values = @solr_doc[solr_key.to_s] || []
      values = values.first if values.size == 1
      metadata[metadata_key] = values unless values.empty?
    end

    metadata.merge! contributors
    metadata.merge! creator
    metadata['created'] = date(true) if date(true)
    metadata['date'] = date if date
    metadata['abstract'] = abstract if abstract
    metadata['identifier'] = identifier if identifier
    metadata['local_identifier'] = local_identifier if local_identifier

    metadata
  end

  def contributors
    return {} unless @solr_doc['related_name_json_1display']

    contributors = {}
    JSON.parse(@solr_doc['related_name_json_1display'].first).each do |role, names|
      contributors[check_role(role)] = names
    end
    contributors
  end

  def creator
    role = check_role((@solr_doc['marc_relator_display'] || []).first)
    return { role => @solr_doc['author_display'].first } unless role == 'contributor'
    {}
  end

  def check_role(label)
    role = (label || '').parameterize(separator: '_').singularize
    RELATORS.include?(role) ? role : 'contributor'
  end

  def date(expanded = false)
    return @solr_doc['compiled_created_display'].first if expanded == false && @solr_doc['compiled_created_display']
    return unless @solr_doc['pub_date_start_sort']
    date = @solr_doc['pub_date_start_sort'].first
    date += "-01-01T00:00:00Z" if expanded
    end_date = @solr_doc['pub_date_end_sort'] || []
    unless end_date.empty?
      date += expanded ? "/" + end_date.first + "-12-31T23:59:59Z" : "-" + end_date.first
    end

    date
  end

  def abstract
    (@solr_doc['summary_note_display'] || []).first
  end

  def iso_codes
    lang = language_codes.map { |l| LanguageService.loc_to_iso(l) }.compact.uniq
    lang.size == 1 ? lang.first : lang
  end

  def title
    return [ vernacular_title, roman_title ] unless vernacular_title.nil?
    roman_title unless roman_title.nil?
  end

  def vernacular_title
    @vernacular_title ||= begin
      vtitle = Traject::Macros::Marc21.trim_punctuation (@solr_doc['title_citation_display'] || []).second
      { "@value": vtitle, "@language": title_language } if vtitle
    end
  end

  def roman_title
    lang = vernacular_title.nil? ? title_language : title_language + "-Latn"
    if roman_display_title
      return roman_display_title unless lang
      return { "@value": roman_display_title, "@language": lang }
    end
  end

  def roman_display_title
    return unless @solr_doc['title_citation_display']
    Traject::Macros::Marc21.trim_punctuation @solr_doc['title_citation_display'].first
  end

  def title_language
    lang = language_codes.first
    LanguageService.loc_to_iso(lang)
  end

  # Generate the identifier from MARC 856 field values
  # @return [String] identifier
  def identifier
    electronic_locations.first&.identifier
  end

  def local_identifier
    return unless @solr_doc['standard_no_1display']
    json = JSON.parse(@solr_doc['standard_no_1display'].first)
    return json['Dclib']
  end

  def metadata_map
    {
      author_display:        'creator',
      call_number_display:   'call_number',
      description_display:   'extent',
      edition_display:       'edition',
      format:                'format',
      genre_facet:           'type',
      notes_display:         'description',
      pub_created_display:   'publisher',
      subject_facet:         'subject',
      coverage_display:      'coverage',
      title_sort:            'title_sort',
      alt_title_246_display: 'alternative',
      scale_display:         'cartographic_scale',
      projection_display:    'cartographic_projection',
      geocode_display:       'spatial',
      contents_display:      'contents',
      geo_related_record_display: 'relation',
      electronic_access_1display: 'references'
    }
  end

  private

    # Access the MARC language codes (excluding cases where "multiple languages" are explicitly coded)
    # @see https://www.loc.gov/marc/languages/
    # @return [Array<String>]
    def language_codes
      (@solr_doc['language_code_s'] || []).reject { |l| l == 'mul' }
    end

    # Construct the models for the electronic locations
    # @return [Array<ElectronicLocation>]
    def electronic_locations
      @electronic_locations ||= ElectronicLocationsFactory.build(@solr_doc)
    end
end
