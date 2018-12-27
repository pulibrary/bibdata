# encoding: UTF-8
# Traject config goes here
require 'traject/macros/marc21_semantics'
require 'traject/macros/marc_format_classifier'
require 'bundler/setup'

extend Traject::Macros::Marc21Semantics
extend Traject::Macros::MarcFormats

settings do
  provide "solr.url", "http://localhost:8983/solr/blacklight-core-development" # default
  provide "solr.version", "7.1.0"
  provide "marc_source.type", "binary"
  provide "solr_writer.max_skipped", "50"
  provide "marc4j_reader.source_encoding", "UTF-8"
  provide "log.error_file", "./log/traject-error.log"
  provide "allow_duplicate_values", false
  provide "solr_writer.commit_on_close", "true"
end

$LOAD_PATH.unshift(File.expand_path('../../', __FILE__)) # include marc_to_solr directory so local translation_maps can be loaded

to_field 'id', extract_marc('001', first: true)

to_field 'marc_display', serialized_marc(format: 'xml', binary_escape: false, allow_oversized: true)

to_field 'name_s', extract_marc('100abcdefghjklmnopqrstvxyz:110abcdefghklmnoprstvxyz:111acdefghjklnpqstvxyz')

to_field 'title_s', extract_marc('130adfghklmnoprstvxyz')

to_field 'named_event_s', extract_marc('147acdgvxyz')

to_field 'chronological_term_s', extract_marc('148avxyz')

to_field 'subject_s', extract_marc('150abgvxyz')

to_field 'geographic_name_s', extract_marc('151agvxyz')

to_field 'genre_s', extract_marc('155avxyz')

to_field 'medium_of_performance_heading_s', extract_marc('162a')

to_field 'general_subdivision_s', extract_marc('180vxyz')
to_field 'geographic_subdivision_s', extract_marc('181vxyz')
to_field 'chronological_subdivision_s', extract_marc('182vxyz')
to_field 'form_subdivision_s', extract_marc('185vxyz')

to_field 'birth_date_s', extract_marc('046f')
to_field 'death_date_s', extract_marc('046g')
to_field 'beginning_single_date_s', extract_marc('046k')
to_field 'ending_date_s', extract_marc('046l')
to_field 'aggregated_starting_date_s', extract_marc('046o')
to_field 'aggregated_ended_date_s', extract_marc('046p')
to_field 'establishment_date_s', extract_marc('046q')
to_field 'termination_date_s', extract_marc('046r')
to_field 'start_period_s', extract_marc('046s')
to_field 'end_period_s', extract_marc('046t')
to_field 'beginning_single_date_s', extract_marc('046k')
to_field 'ending_date_s', extract_marc('046l')
to_field 'source_for_046_s', extract_marc('046uv')

to_field 'content_type_s', extract_marc('336a')

to_field 'notation_format_s', extract_marc('348a')

to_field 'other_attributes_s', extract_marc('368abcd')
to_field 'other_attributes_period_s', extract_marc('368st')

to_field 'birth_place_s', extract_marc('370a')
to_field 'death_place_s', extract_marc('370b')
to_field 'associated_country_s', extract_marc('370c')
to_field 'residence_hq_s', extract_marc('370e')
to_field 'other_associated_place_s', extract_marc('370f')
to_field 'origin_of_work_s', extract_marc('370g')
to_field 'relationship_to_heading_s', extract_marc('370i')
to_field 'place_period_s', extract_marc('368st')

to_field 'field_of_activity_s', extract_marc('372a')
to_field 'activity_period_s', extract_marc('372st')

to_field 'associated_group_s', extract_marc('373a')
to_field 'associated_group_period_s', extract_marc('373st')

to_field 'occupation_s', extract_marc('374a')
to_field 'occupation_period_s', extract_marc('374st')

to_field 'family_info_s', extract_marc('376abc')
to_field 'family_info_period_s', extract_marc('376st')

to_field 'associated_language_s', extract_marc('377a', translation_map: 'marc_languages')
to_field 'associated_language_term_s', extract_marc('377b')

to_field 'fuller_form_s', extract_marc('378q')

to_field 'form_of_work_s', extract_marc('380a')
to_field 'other_distinguishing_characteristics_s', extract_marc('381a')

to_field 'work_performance_medium_s', extract_marc('382|0*|a')
to_field 'partial_work_performance_medium_s', extract_marc('382|1*|a')
to_field 'soloist_s', extract_marc('382b')
to_field 'doubling_instrument_s', extract_marc('382d')
to_field 'alternative_performance_medium_s', extract_marc('382p')
to_field 'total_number_of_performers_s', extract_marc('382s')
to_field 'performance_medium_note_s', extract_marc('382v')

to_field 'music_work_number_s', extract_marc('383a')
to_field 'music_key_s', extract_marc('384|0*|a:384| *|a')
to_field 'transposed_key_s', extract_marc('384|1*|a')

to_field 'creator_characteristics_s', extract_marc('386abimn')
to_field 'creation_time_period_s', extract_marc('388a')

to_field 'references_name_s', extract_marc('400abcdefghjklmnopqrstvxyz:410abcdefghklmnoprstvxyz:411acdefghjklnpqstvxyz')
to_field 'references_title_s', extract_marc('430adfghklmnoprstvxyz')
to_field 'references_named_event_s', extract_marc('447acdgvxyz')
to_field 'references_chronological_term_s', extract_marc('448avxyz')
to_field 'references_subject_s', extract_marc('450abgvxyz')
to_field 'references_geographic_name_s', extract_marc('451agvxyz')
to_field 'references_genre_s', extract_marc('455avxyz')
to_field 'references_medium_of_performance_heading_s', extract_marc('462a')
to_field 'references_general_subdivision_s', extract_marc('480vxyz')
to_field 'references_geographic_subdivision_s', extract_marc('481vxyz')
to_field 'references_chronological_subdivision_s', extract_marc('482vxyz')
to_field 'references_form_subdivision_s', extract_marc('485vxyz')

to_field 'see_also_name_s', extract_marc('500abcdefghjklmnopqrstvxyz:510abcdefghklmnoprstvxyz:511acdefghjklnpqstvxyz')
to_field 'see_also_title_s', extract_marc('530adfghklmnoprstvxyz')
to_field 'see_also_named_event_s', extract_marc('547acdgvxyz')
to_field 'see_also_chronological_term_s', extract_marc('548avxyz')
to_field 'see_also_subject_s', extract_marc('550abgvxyz')
to_field 'see_also_geographic_name_s', extract_marc('551agvxyz')
to_field 'see_also_genre_s', extract_marc('555avxyz')
to_field 'see_also_medium_of_performance_heading_s', extract_marc('562a')
to_field 'see_also_general_subdivision_s', extract_marc('580vxyz')
to_field 'see_also_geographic_subdivision_s', extract_marc('581vxyz')
to_field 'see_also_chronological_subdivision_s', extract_marc('582vxyz')
to_field 'see_also_form_subdivision_s', extract_marc('585vxyz')

to_field 'vocab_type_s' do |record, accumulator|
  if record['010'] && record['010']['a']
    vocab = nil
    main_field = record.fields('100'..'199').first
    if %w[100 110 111 130].include?(main_field.tag)
      subfields = main_field.subfields.map(&:code)
      vocab = if (%w[v x] & subfields).empty?
                'names'
              else
                'subjects'
              end
    elsif main_field.tag == '150'
      vocab = 'subjects'
    elsif main_field.tag == '155'
      vocab = 'genreForms'
    end
  end
  accumulator << vocab
end
