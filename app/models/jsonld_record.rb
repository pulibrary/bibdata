class JSONLDRecord
  def initialize(solr_doc)
    @solr_doc = solr_doc
  end

  def to_h
    metadata = { title: title, description: description }

    metadata_map.each do |solr_key, metadata_key|
      values = @solr_doc[solr_key.to_s] || []
      values = values.first if values.size == 1
      metadata[metadata_key] = values unless values.empty?
    end

    contrib = contributors
    metadata['contributor'] = contrib unless contrib.empty?

    metadata
  end

  def contributors
    return [] unless @solr_doc['related_name_json_1display']
    JSON.parse(@solr_doc['related_name_json_1display'].first).values.flatten.uniq
  end

  def description
    (@solr_doc['summary_note_display'] || [""]).first
  end

  def title
    vernacular_title.nil? ? roman_title : [ vernacular_title, roman_title ]
  end

  def vernacular_title
    vtitle = (@solr_doc['title_citation_display'] || []).second
    return { "@value": vtitle, "@language": title_language } if vtitle
  end

  def roman_title
    lang = vernacular_title.nil? ? title_language : title_language + "-Latn"
    { "@value": @solr_doc['title_citation_display'].first, "@language": lang }
  end

  def title_language
    lang = @solr_doc['language_code_s'].first
    return LanguageService.label_to_iso(@solr_doc['language_facet'].second) if lang == 'mul'
    return LanguageService.loc_to_iso(lang)
  end

  def metadata_map
    {
      author_display:        'creator',
      pub_date_display:      'date',
      description_display:   'description',
      edition_display:       'edition',
      format:                'format',
      genre_facet:           'genre',
      language_facet:        'language',
      language_code_s:       'language_code',
      notes_display:         'note',
      pub_citation_display:  'publication',
      subject_facet:         'subject'
    }
  end
end
