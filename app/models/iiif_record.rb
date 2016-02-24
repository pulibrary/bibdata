class IIIFRecord
  def initialize(solr_doc)
    @solr_doc = solr_doc
  end

  def to_json
    { label: label, description: description, metadata: metadata }
  end

  def contributors
    return [] unless @solr_doc['related_name_json_1display']
    JSON.parse(@solr_doc['related_name_json_1display'].first).values.flatten.uniq
  end

  def description
    (@solr_doc['summary_note_display'] || [""]).first
  end

  def label
    (@solr_doc['title_citation_display'] || [""]).first
  end

  def metadata
    metadata = []

    metadata_map.each do |solr_key, metadata_key|
      values = @solr_doc[solr_key.to_s] || []
      values = values.first if values.size == 1
      metadata << { label: metadata_key, value: values } unless values.empty?
    end

    contrib = contributors
    metadata << { label: 'contributor', value: contrib } unless contrib.empty?

    metadata
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
