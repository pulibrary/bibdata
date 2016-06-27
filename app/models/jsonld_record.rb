class JSONLDRecord
  def initialize(solr_doc)
    @solr_doc = solr_doc
  end

  def to_h
    metadata = { title: title, language: language_codes }

    metadata_map.each do |solr_key, metadata_key|
      values = @solr_doc[solr_key.to_s] || []
      values = values.first if values.size == 1
      metadata[metadata_key] = values unless values.empty?
    end

    metadata.merge! contributors
    metadata.merge! creator
    metadata['created'] = date(true)
    metadata['date'] = date
    metadata['description'] = description if description

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
    role = (label || '').parameterize('_').singularize
    RELATORS.include?(role) ? role : 'contributor'
  end

  def date(expanded = false)
    date = @solr_doc['pub_date_start_sort'].first
    date += "-01-01T00:00:00Z" if expanded
    end_date = @solr_doc['pub_date_end_sort'] || []
    unless end_date.empty?
      date += expanded ? "/" + end_date.first + "-12-31T23:59:59Z" : "-" + end_date.first
    end

    date
  end

  def description
    (@solr_doc['summary_note_display'] || []).first
  end

  def language_codes
    lang = @solr_doc['language_code_s']
    @solr_doc['language_facet'].each do |label|
      lang << LanguageService.label_to_iso(label) unless label == 'Multiple'
    end
    lang = lang.uniq
    lang.size == 1 ? lang.first : lang
  end

  def title
    vernacular_title.nil? ? roman_title : [ vernacular_title, roman_title ]
  end

  def vernacular_title
    vtitle = Traject::Macros::Marc21.trim_punctuation (@solr_doc['title_citation_display'] || []).second
    return { "@value": vtitle, "@language": title_language } if vtitle
  end

  def roman_title
    lang = vernacular_title.nil? ? title_language : title_language + "-Latn"
    { "@value": roman_display_title, "@language": lang }
  end

  def roman_display_title
    Traject::Macros::Marc21.trim_punctuation @solr_doc['title_citation_display'].first
  end

  def title_language
    lang = @solr_doc['language_code_s'].first
    return LanguageService.label_to_iso(@solr_doc['language_facet'].second) if lang == 'mul'
    return LanguageService.loc_to_iso(lang)
  end

  def metadata_map
    {
      author_display:        'creator',
      call_number_display:   'call_number',
      description_display:   'extent',
      edition_display:       'edition',
      format:                'format',
      genre_facet:           'genre',
      notes_display:         'note',
      pub_created_display:   'publisher',
      subject_facet:         'subject'
    }
  end
end
