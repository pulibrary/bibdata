# encoding: UTF-8
# Traject config goes here
require 'traject/macros/marc21_semantics'
require 'traject/macros/marc_format_classifier'
require 'bundler/setup'
require './lib/format'
require './lib/princeton_marc'
require './lib/location_extract'
require 'stringex'
require 'library_stdnums'
require 'time'
extend Traject::Macros::Marc21Semantics
extend Traject::Macros::MarcFormats

settings do
  provide "solr.url", "http://localhost:8983/solr/blacklight-core" # default
  provide "solr.version", "4.10.0"
  provide "marc_source.type", "xml"
  provide "solrj_writer.commit_on_close", "true"
  provide "solr_writer.max_skipped", "50"
  provide "marc4j_reader.source_encoding", "UTF-8"
  provide "log.error_file", "/tmp/error.log"
end

update_locations
$LOAD_PATH.unshift('.') # include current directory so local translation_maps can be loaded



to_field 'id', extract_marc('001', :first => true)

to_field 'cjk_all', extract_all_marc_values

# Author/Artist:
#    100 XX aqbcdek A aq
#    110 XX abcdefgkln A ab
#    111 XX abcdefgklnpq A ab

# previously set to not include alternate script and to have only first value
# to put back in add: alternate_script: false, first: true
to_field 'author_display', extract_marc('100aqbcdk:110abcdfgkln:111abcdfgklnpq', trim_punctuation: true)
to_field 'author_sort', extract_marc('100aqbcdk:110abcdfgkln:111abcdfgklnpq', trim_punctuation: true, first: true) # do |record, accumulator|
to_field 'author_citation_display', extract_marc('100a:110a:111a:700a:710a:711a', trim_punctuation: true, alternate_script: false)

to_field 'author_roles_1display' do |record, accumulator|
  authors = process_author_roles(record)
  accumulator[0] = authors.to_json.to_s
end

to_field 'cjk_author', extract_marc('100aqbcdek:110abcdefgkln:111abcdefgklnpq', trim_punctuation: true, alternate_script: :only)

to_field 'author_s' do |record, accumulator|
  names = process_names(record)
  accumulator.replace(names)
end

# for now not separate
# to_field 'author_vern_display', extract_marc('100aqbcdek:110abcdefgkln:111abcdefgklnpq', :trim_punctuation => true, :alternate_script => :only, :first => true)

to_field 'marc_relator_display' do |record, accumulator|
  MarcExtractor.cached("100:110:111").collect_matching_lines(record) do |field, spec, extractor|
    relator = 'Author'
    field.subfields.each do |s_field|
      if s_field.code == 'e'
        relator = s_field.value.capitalize.gsub(/[[:punct:]]?$/,'')
        break
      end
      if s_field.code == '4'
        relator = Traject::TranslationMap.new("relators")[s_field.value]
      end
    end
    accumulator << relator
    break
  end
end

# Uniform title:
#    130 XX apldfhkmnorst T ap
#    240 XX {a[%}pldfhkmnors"]" T ap
to_field 'uniform_title_s', extract_marc('100t:110t:111t:130apldfhkmnorst:240apldfhkmnors', :trim_punctuation => true, :first => true)


# Title:
#    245 XX abchknps
to_field 'title_display', extract_marc('245abcfghknps', :alternate_script => false)


to_field 'title_vern_display', extract_marc('245abcfghknps', :alternate_script => :only)
to_field 'cjk_title', extract_marc('245abcfghknps', :alternate_script => :only)

# to_field 'title_sort', marc_sortable_title
to_field 'title_sort' do |record, accumulator|
  MarcExtractor.cached("245abcfghknps", :alternate_script => false).collect_matching_lines(record) do |field, spec, extractor|
    str = extractor.collect_subfields(field, spec).first
    str = str.slice(field.indicator2.to_i, str.length) if str
    accumulator << str if accumulator[0].nil?
  end
end

to_field 'title_vern_sort' do |record, accumulator|
  MarcExtractor.cached("245abcfghknps", :alternate_script => :only).collect_matching_lines(record) do |field, spec, extractor|
    str = extractor.collect_subfields(field, spec).first
    str = str.slice(field.indicator2.to_i, str.length) if str
    accumulator << str if accumulator[0].nil?
  end
end

# roman and alt-script title with and without non-filing characters, excluding $h
to_field 'title_no_h_index' do |record, accumulator|
  MarcExtractor.cached("245abcfgknps").collect_matching_lines(record) do |field, spec, extractor|
    str = extractor.collect_subfields(field, spec).first
    if str
      accumulator << str
      str = str.slice(field.indicator2.to_i, str.length)
      accumulator << str
    end
  end
  accumulator.uniq!
end

to_field 'title_t', extract_marc('245abchknps', :alternate_script => false, :first => true)
to_field 'title_citation_display', extract_marc('245ab', :alternate_script => false, :first => true)

## Title and Title starts with index-only fields ##
#################################################
to_field 'series_title_index', extract_marc('400t:410t:411t:440anpvx:490avx')

to_field 'content_title_index', extract_marc('505t')

to_field 'contains_title_index', extract_marc('700|12|t:710|12|t:711|12|t')

to_field 'linked_title_index', extract_marc('800t:810t:811t:830adfghklmnoprstv:840anpv')

to_field 'series_ae_index', extract_marc('800t:810t:811t:830adfghklmnoprstv:840anpv')
#################################################

# Compiled/Created:
#    245 XX fg
to_field 'compiled_created_display', extract_marc('245fg')
to_field 'compiled_created_t', extract_marc('245abchknps')

# Edition
#    250 XX ab
to_field 'edition_display', extract_marc('250ab')

# Published/Created:
#    260 XX abcefg
#    264 XX abc
to_field 'pub_created_display', extract_marc('260abcefg:264abcefg')
to_field 'pub_created_s', extract_marc('260abcefg:264abcefg', :first => true)

to_field 'pub_citation_display' do |record, accumulator|
  pub_info = set_pub_citation(record)
  accumulator.replace(pub_info)
end

to_field 'pub_date_display' do |record, accumulator|
    accumulator << record.date_from_008
end


to_field 'pub_date_start_sort' do |record, accumulator|
    accumulator << record.date_from_008
end

to_field 'pub_date_end_sort' do |record, accumulator|
    accumulator << record.end_date_from_008
end

to_field 'cataloged_tdt', extract_marc('959a') do |record, accumulator|
  accumulator[0] = Time.parse(accumulator[0]).utc.strftime("%Y-%m-%dT%H:%M:%SZ") unless accumulator[0].nil?
end


# format - allow multiple - "first" one is used for thumbnail
to_field 'format' do |record, accumulator|
  formats = Format.new(record).bib_format
  formats.each {|fmt| accumulator << Traject::TranslationMap.new("format")[fmt]}
end

# Medium/Support:
#    340 XX 3abcdefhl
to_field 'medium_support_display', extract_marc('340')


# Electronic access:
#    3000 - really 856
#    most have first sub as 4, a few 0,1,7
#    treat the same
#    $u is for the link
#    $y and $3 for display text for link
#    $z additional display text
#    display host name if missing $y or $3
to_field 'electronic_access_1display' do |record, accumulator|
  links = electronic_access_links(record)
  accumulator[0] = links.to_json.to_s unless links == {}
end

# Description:
   # 254 XX a
   # 255 XX abcdefg
   # 342 XX 2abcdefghijklmnopqrstuv
   # 343 XX abcdefghi
   # 352 XX abcdegi
   # 355 XX abcdefghj
   # 507 XX ab
   # 256 XX a
   # 516 XX a
   # 753 XX abc
   # 755 XX axyz
   # 300 XX 3abcefg
   # 306 XX a
   # 515 XX a
   # 362 XX az
to_field 'description_display', extract_marc('254a:255abcdefg:3422abcdefghijklmnopqrstuv:343abcdefghi:352abcdegi:355abcdefghj:507ab:256a:516a:753abc:755axyz:3003abcefg:515a:362az')
to_field 'description_t', extract_marc('254a:255abcdefg:3422abcdefghijklmnopqrstuv:343abcdefghi:352abcdegi:355abcdefghj:507ab:256a:516a:753abc:755axyz:3003abcefg:515a:362az')

# Arrangement:
# #    351 XX 3abc
to_field 'arrangement_display', extract_marc('351abc')

# Translation of:
#    765 XX at
to_field 'translation_of_display', extract_marc('765at')


# Translated as:
#    767 XX at
to_field 'translated_as_display', extract_marc('767at')

# Issued with:
#    777 XX at
to_field 'issued_with_display', extract_marc('777at')

# Continues:
#    780 00 at
#    780 02 at
to_field 'continues_display', extract_marc('780|00|a:780|02|at')

# Continues in part:
#    780 01 at
#    780 03 at
to_field 'continues_in_part_display', extract_marc('780|01|a:780|03|at')

# Formed from:
#    780 04 at
to_field 'formed_from_display', extract_marc('780|04|at')

# Absorbed:
#    780 05 at
to_field 'absorbed_display', extract_marc('780|05|at')

# Absorbed in part:
#    780 06 at
to_field 'absorbed_in_part_display', extract_marc('780|06|at')

# Separated from:
#    780 07 at
to_field 'separated_from_display', extract_marc('780|07|at')

# Continued by:
#    785 00 at
#    785 02 at
to_field 'continued_by_display', extract_marc('785|00|a:785|02|at')

# Continued in part by:
#    785 01 at
#    785 03 at
to_field 'continued_in_part_by_display', extract_marc('785|01|a:785|03|at')

# Absorbed by:
#    785 04 at
to_field 'absorbed_by_display', extract_marc('785|04|at')

# Absorbed in part by:
#    785 05 at
to_field 'absorbed_in_part_by_display', extract_marc('785|05|at')

# Split into:
#    785 06 at
to_field 'split_into_display', extract_marc('785|06|at')

# Merged to form:
#    785 07 at
to_field 'merged_to_form_display', extract_marc('785|07|at')

# Changed back to:
#    785 08 at
to_field 'changed_back_to_display', extract_marc('785|08|at')

# Frequency:
#    310 XX ab
to_field 'frequency_display', extract_marc('310ab')

# Former frequency:
#    321 XX a
to_field 'former_frequency_display', extract_marc('321a')

# Has supplement:
#    770 XX at
to_field 'has_supplement_display', extract_marc('770at')

# Supplement to:
#    772 XX at
to_field 'supplement_to_display', extract_marc('772at')

# Linking notes:
#    580 XX a
to_field 'linking_notes_display', extract_marc('580a')

# Subseries of:
#    760 XX at
to_field 'subseries_of_display', extract_marc('760at')

# Has subseries:
#    762 XX at
to_field 'has_subseries_display', extract_marc('762at')

# Series:
#    400 XX abcdefgklnpqtuvx
#    410 XX abcdefgklnptuvx
#    411 XX acdefgklnpqtuv
#    440 XX anpvx
#    490 XX avx
#    800 XX abcdefghklmnopqrstuv
#    810 XX abcdefgklnt
#    811 XX abcdefghklnpqstuv
#    830 XX adfghklmnoprstv
#    840 XX anpv
to_field 'series_display', extract_marc('400abcdefgklnpqtuvx:410abcdefgklnptuvx:411acdefgklnpqtuv:440anpvx:490avx:800abcdefghklmnopqrstuv:810abcdefgklnt:811abcdefghklnpqstuv:830adfghklmnoprstv:840anpv')

# Other version(s):
#    3500 020Z020A
#    3500 020A020Z
#    3500 024A022A
#    3500 022A024A
#    3500 BBID776W
#    3500 BBID787W
#    3500 776X022A
#    3500 022A776X
#    3500 020A776Z
#    3500 776Z020A
# to_field 'Other version(s)_display', extract_marc()
# # #    3500 020Z020A
# # #    3500 020A020Z
# # #    3500 024A022A
# # #    3500 022A024A
# # #    3500 BBID776W
# # #    3500 BBID787W
# # #    3500 776X022A
# # #    3500 022A776X
# # #    3500 020A776Z
# # #    3500 776Z020A

# Contained in:
#    3500 BBID773W
to_field 'contained_in_s', extract_marc('773w')

# Related record(s):
#    3500 BBID774W
to_field 'related_record_s', extract_marc('774w')

# Restrictions note:
#    506 XX 3abcde
to_field 'restrictions_note_display', extract_marc('5063abcde')

# Biographical/Historical note:
#    545 XX ab
to_field 'biographical_historical_note_display', extract_marc('545ab')

# Summary note:
#    520 XX 3ab
to_field 'summary_note_display', extract_marc('5203ab')

# Notes:
#    500 XX 3a
#    501 XX a
#    503 XX a
#    502 XX a
#    504 XX ab
#    508 XX a
#    513 XX ab
#    514 XX abcdefghijkm
#    515 XX a
#    518 XX 3a
#    521 XX 3ab
#    522 XX a
#    523 XX a
#    525 XX a
#    527 XX a
#    534 XX abcefklmnpt
#    535 XX 3abcdg
#    536 XX abcdefgh
#    537 XX a
#    538 XX a
#    544 XX 3abcden
#    547 XX a
#    550 XX a
#    556 XX a
#    562 XX 3abcde
#    565 XX 3abcde
#    567 XX a
#    570 XX a
to_field 'notes_display', extract_marc('5003a')
to_field 'with_notes_display', extract_marc('501a')
to_field 'bibliographic_notes_display', extract_marc('503a') #obsolete
to_field 'dissertation_notes_display', extract_marc('502a')
to_field 'bib_ref_notes_display', extract_marc('504ab')
to_field 'scale_notes_display', extract_marc('507ab') #added
to_field 'credits_notes_display', extract_marc('508a')
to_field 'type_period_notes_display', extract_marc('513ab')
to_field 'data_quality_notes_display', extract_marc('514abcdefghijkm')
to_field 'numbering_pec_notes_display', extract_marc('515a')
to_field 'type_comp_data_notes_display', extract_marc('516a') #added
to_field 'date_place_event_notes_display', extract_marc('5183a')
to_field 'target_aud_notes_display', extract_marc('5213ab')
to_field 'geo_cov_notes_display', extract_marc('522a')
to_field 'time_period_notes_display', extract_marc('523a') #obsolete
to_field 'supplement_notes_display', extract_marc('525a')
to_field 'study_prog_notes_display', extract_marc('526abcdixz') #added
to_field 'censorship_notes_display', extract_marc('527a') #obsolete
to_field 'reproduction_notes_display', extract_marc('5333abcdefmn')
to_field 'original_version_notes_display', extract_marc('534abcefklmnpt')
to_field 'location_originals_notes_display', extract_marc('5353abcdg')
to_field 'funding_info_notes_display', extract_marc('536abcdefgh')
to_field 'source_data_notes_display', extract_marc('537a') #obsolete
to_field 'system_details_notes_display', extract_marc('538a')
to_field 'related_copyright_notes_display', extract_marc('542') #is this in any record?
to_field 'location_other_arch_notes_display', extract_marc('5443abcden')
to_field 'former_title_complex_notes_display', extract_marc('547a')
to_field 'issuing_body_notes_display', extract_marc('550a')
to_field 'info_document_notes_display', extract_marc('556a')
to_field 'copy_version_notes_display', extract_marc('5623abcde')
to_field 'case_file_notes_display', extract_marc('5653abcde')
to_field 'methodology_notes_display', extract_marc('567a')
to_field 'editor_notes_display', extract_marc('570a') #added
to_field 'accumulation_notes_display', extract_marc('584ab') #added
to_field 'awards_notes_display', extract_marc('586a') #added
to_field 'source_desc_notes_display', extract_marc('588a') #added

# Binding note:
#    563 XX au3
to_field 'binding_note_display', extract_marc('563au3')

# Local notes:
#    590 XX a
#    591 XX a
#    592 XX a
to_field 'local_notes_display', extract_marc('590a:591a:592a')

# Rights and reproductions note:
#    540 XX 3abcd
to_field 'rights_reproductions_note_display', extract_marc('5403abcd')

# Exhibitions note:
#    585 XX 3a
to_field 'exhibitions_note_display', extract_marc('5853a')

# Participant(s)/Performer(s):
#    511 XX a
to_field 'participant_performer_display', extract_marc('511a')

# Language(s):
#    546 XX 3a
to_field 'language_display', extract_marc('5463a')

to_field "language_facet", marc_languages


# Script:
#    546 XX b
to_field 'script_display', extract_marc('546b')

to_field 'language_code_s', extract_marc('008[35-37]')

# Contents:
#    505 0X agrt
#    505 8X agrt
to_field 'contents_display', extract_marc('505|0*|agrt:505|8*|agrt')

# Incomplete contents:
#    505 1X agrt
to_field 'incomplete_contents_display', extract_marc('505|1*|agrt')

# Partial contents:
#    505 2X agrt
to_field 'partial_contents_display', extract_marc('505|2*|agrt')

# Provenance:
#    561 XX 3ab
#    796 XX abcqde
#    797 XX abcqde
to_field 'provenance_display', extract_marc('5613ab:796abcqde:797abcqde')

# Source of acquisition:
#    541 XX abcdefhno36
to_field 'source_acquisition_display', extract_marc('541abcdefhno36')

# Publications about:
#    581 XX az36
to_field 'publications_about_display', extract_marc('581az36')

# Indexed in:
#    510 0X 3abc
#    510 1X 3abc
#    510 2X 3abc
to_field 'indexed_in_display', extract_marc('510|0*|3abc:510|1*|3abc:510|2*|3abc')

# References:
#    510 3X 3abc
#    510 4X 3abc
to_field 'references_display', extract_marc('510|3*|3abc:510|4*|3abc')

# Cite as:
#    524 XX 23a
to_field 'cite_as_display', extract_marc('52423a')

# Other format(s):
#    530 XX 3abcd
#    533 XX 3abcdefmn
to_field 'other_format_display', extract_marc('5303abcd')

# Cumulative index/Finding aid:
#    555 XX 3abcd
to_field 'cumulative_index_finding_aid_display', extract_marc('5553abcd')

# Subject(s):
#    600 XX acdfklmnopqrst{v--%}{x--%}{y--%}{z--%} S abcdfklmnopqrtvxyz
#    610 XX abfklmnoprst{v--%}{x--%}{y--%}{z--%} S abfklmnoprstvxyz
#    611 XX abcdefgklnpqst{v--%}x--%}{y--%}{z--%} S abcdefgklnpqstvxyz
#    630 XX adfgklmnoprst{v--%}{x--%}{y--%}{z--%} S adfgklmnoprstvxyz
#    650 XX abc{v--%}{x--%}{z--%}{y--%} S abcvxyz
#    651 XX a{v--%}{x--%}{y--%}{z--%} S avxyz
to_field 'subject_display' do |record, accumulator|
  subjects = process_subject_facet(record)
  accumulator.replace(subjects)
end

# used for the browse lists and hierarchical subject facet
to_field 'subject_facet' do |record, accumulator|
  subjects = process_subject_facet(record)
  accumulator.replace(subjects)
end

# used for split subject topic facet
to_field 'subject_topic_facet' do |record, accumulator|
  subjects = process_subject_topic_facet(record)
  accumulator.replace(subjects)
end

to_field 'lc_1letter_facet' do |record, accumulator|
  if record['050']
    if record['050']['a']
      first_letter = record['050']['a'].lstrip.slice(0, 1)
      letters = /([[:alpha:]])*/.match(record['050']['a'])[0]
      accumulator << Traject::TranslationMap.new("callnumber_map")[first_letter] if !Traject::TranslationMap.new("callnumber_map")[letters].nil?
    end
  end
end

to_field 'lc_rest_facet' do |record, accumulator|
  if record['050']
    if record['050']['a']     
      letters = /([[:alpha:]])*/.match(record['050']['a'])[0]
      accumulator << Traject::TranslationMap.new("callnumber_map")[letters]
    end
  end
end

to_field 'sudoc_facet' do |record, accumulator|
  MarcExtractor.cached('086|0 |a').collect_matching_lines(record) do |field, spec, extractor|
    letters = /([[:alpha:]])*/.match(extractor.collect_subfields(field, spec).first)[0] if /([[:alpha:]])*/.match(extractor.collect_subfields(field, spec).first)
    accumulator << Traject::TranslationMap.new("sudocs")[letters] if !Traject::TranslationMap.new("sudocs")[letters].nil?    
  end
end

to_field 'call_number_scheme_facet' do |record, accumulator|
  if record['050']
    if record['050']['a']
      first_letter = record['050']['a'].lstrip.slice(0, 1)
      letters = /([[:alpha:]])*/.match(record['050']['a'])[0]
      accumulator << "Library of Congress" if !Traject::TranslationMap.new("callnumber_map")[letters].nil?
    end
  end  
  MarcExtractor.cached('086|0 |a').collect_matching_lines(record) do |field, spec, extractor|
    letters = /([[:alpha:]])*/.match(extractor.collect_subfields(field, spec).first)[0] if /([[:alpha:]])*/.match(extractor.collect_subfields(field, spec).first)
    accumulator << "Superintendent of Documents" if !Traject::TranslationMap.new("sudocs")[letters].nil?    
  end
end

to_field 'call_number_group_facet' do |record, accumulator|
  MarcExtractor.cached('050a').collect_matching_lines(record) do |field, spec, extractor|
    if record['050']['a']
      if /([[:alpha:]])*/.match(extractor.collect_subfields(field, spec).first)  
        letters = /([[:alpha:]])*/.match(extractor.collect_subfields(field, spec).first)[0]
        first_letter = record['050']['a'].lstrip.slice(0, 1)
        accumulator << Traject::TranslationMap.new("callnumber_map")[first_letter] if !Traject::TranslationMap.new("callnumber_map")[letters].nil?  
      end
    end
  end  
  MarcExtractor.cached('086|0 |a').collect_matching_lines(record) do |field, spec, extractor|
    letters = /([[:alpha:]])*/.match(extractor.collect_subfields(field, spec).first)[0] if /([[:alpha:]])*/.match(extractor.collect_subfields(field, spec).first)
    accumulator << Traject::TranslationMap.new("sudocs_split")[letters] if !Traject::TranslationMap.new("sudocs_split")[letters].nil? 
  end
end

to_field 'call_number_full_facet' do |record, accumulator|
  MarcExtractor.cached('050a').collect_matching_lines(record) do |field, spec, extractor|
    if record['050']['a']
      if /([[:alpha:]])*/.match(extractor.collect_subfields(field, spec).first)    
        letters = /([[:alpha:]])*/.match(extractor.collect_subfields(field, spec).first)[0] 
        accumulator << Traject::TranslationMap.new("callnumber_map")[letters]
      end
    end
  end  
  MarcExtractor.cached('086|0 |a').collect_matching_lines(record) do |field, spec, extractor|
    letters = /([[:alpha:]])*/.match(extractor.collect_subfields(field, spec).first)[0] if /([[:alpha:]])*/.match(extractor.collect_subfields(field, spec).first)
    accumulator << Traject::TranslationMap.new("sudocs")[letters] if !Traject::TranslationMap.new("sudocs")[letters].nil?    
  end
end

# Form/Genre:
#    655 |7 a{v--%}{x--%}{y--%}{z--%} S avxyz
to_field 'form_genre_display', extract_marc('655avxyz')

# 600/610/650/651 $v, $x filtered
# 655 $a, $v, $x filtered
to_field 'genre_facet' do |record, accumulator|
  genres = process_genre_facet(record)
  accumulator.replace(genres)
end

# Related name(s):
#    700 XX aqbcdefghklmnoprstx A aq
#    710 XX abcdefghklnoprstx A ab
#    711 XX abcdefgklnpq A ab

# Json string mapping relator terms and names for display
to_field 'related_name_json_1display' do |record, accumulator|
  rel_name_hash = {}
  MarcExtractor.cached("700aqbcdk:710abcdfgkln:711abcdfgklnpq").collect_matching_lines(record) do |field, spec, extractor|
    rel_name = Traject::Macros::Marc21.trim_punctuation(extractor.collect_subfields(field, spec).first)
    relator = nil
    non_t = true
    field.subfields.each do |s_field|
      if s_field.code == 'e'
        relator = s_field.value.capitalize.gsub(/[[:punct:]]?$/,'')
      end
      if s_field.code == 't'
        non_t = false
        break

      end
      if s_field.code == '4'
        if relator.nil?
          relator = Traject::TranslationMap.new("relators")[s_field.value] || s_field.value 
        end
      end
    end
    relator = 'Related name' if relator.nil?
    rel_name_hash[relator] ? rel_name_hash[relator] << rel_name : rel_name_hash[relator] = [rel_name] if (non_t && !rel_name.nil?)
  end
  unless rel_name_hash == {}
    accumulator[0] = rel_name_hash.to_json.to_s
  end
end

to_field 'related_works_display' do |record, accumulator|
  MarcExtractor.cached('700|1 |aqbcdfghklmnoprstx:710|1 |abcdfghklnoprstx:711|1 |abcdefgklnpqt').collect_matching_lines(record) do |field, spec, extractor|
    rel_work = Traject::Macros::Marc21.trim_punctuation(extractor.collect_subfields(field, spec).first)
    non_t = true
    field.subfields.each do |s_field|
      if s_field.code == 't'
        non_t = false
        break
      end
    end
    accumulator << rel_work unless non_t
  end
end  

to_field 'contains_display' do |record, accumulator|
  MarcExtractor.cached('700|12|aqbcdfghklmnoprstx:710|12|abcdfghklnoprstx:711|12|abcdefgklnpqt').collect_matching_lines(record) do |field, spec, extractor|
    rel_work = Traject::Macros::Marc21.trim_punctuation(extractor.collect_subfields(field, spec).first)
    non_t = true
    field.subfields.each do |s_field|
      if s_field.code == 't'
        non_t = false
        break
      end
    end
    accumulator << rel_work unless non_t
  end
end

to_field 'instrumentation_facet', marc_instrumentation_humanized

# Place name(s):
#    752 XX abcd
to_field 'place_name_display', extract_marc('752abcd')

# Other title(s):
#    246 XX abfnp
#    210 XX ab
#    211 XX a
#    212 XX a
#    214 XX a
#    222 XX ab
#    242 XX abchnp
#    243 XX adfklmnoprs
#    247 XX abfhnp
#    730 XX aplskfmnor
#    740 XX ahnp
to_field 'other_title_index', extract_marc('246abfnp:210ab:211a:212a:214a:222ab:242abchnp:243adfklmnoprs:247abfhnp:730aplskfmnor:740ahnp')

# only include 246 as 'other title' when 2nd indicator missing or 3 and missing $i
to_field 'other_title_display' do |record, accumulator|
  MarcExtractor.cached('246|* |abfnp:246|*3|abfnp:210ab:211a:212a:214a:222ab:242abchnp:243adfklmnoprs:247abfhnp:730aplskfmnor:740ahnp').collect_matching_lines(record) do |field, spec, extractor|
    if field.tag == '246'
      label = field.subfields.select{|s_field| s_field.code == 'i'}.first
      accumulator << extractor.collect_subfields(field, spec).first if label.nil?
    else
      accumulator << extractor.collect_subfields(field, spec).first
    end
  end
end

# 246 hash, 2nd indicator is used for label (hash key), prefer $i if present
to_field 'other_title_1display' do |record, accumulator|
  other_title_hash = {}
  MarcExtractor.cached('246abfnp').collect_matching_lines(record) do |field, spec, extractor|
    label = field.subfields.select{|s_field| s_field.code == 'i'}.first
    if label.nil?
      next if field.indicator2 == ' ' || field.indicator2 == '3'
      label = indicator_label_246(field.indicator2)
    else
      label = label.value
    end
    label = Traject::Macros::Marc21.trim_punctuation(label)
    title = extractor.collect_subfields(field, spec).first
    other_title_hash[label] ? other_title_hash[label] << title : other_title_hash[label] = [title] unless title.nil?
  end
  unless other_title_hash == {}
    accumulator[0] = other_title_hash.to_json.to_s
  end
end

# In:
#    773 XX 3abdghikmnoprst
to_field 'in_display', extract_marc('7733abdghikmnoprst')

# Constituent part(s):
#    774 XX abcdghikmnrstu
to_field 'constituent_part_display', extract_marc('774abcdghikmnrstu')

# ISBN:
#    020 XX a
to_field 'isbn_display', extract_marc('020a')

# ISSN:
#    022 XX a
to_field 'issn_display', extract_marc('022a')

# SuDoc no.:
#    086 XX a
to_field 'sudoc_no_display', extract_marc('086a')

# Tech. report no.:
#    027 XX a
#    088 XX a
to_field 'tech_report_no_display', extract_marc('027a:088a')

# Publisher. no.:
#    028 XX a
to_field 'publisher_no_display', extract_marc('028a')

# Standard no.:
#    010 XX a
#    030 XX a
to_field 'lccn_display', extract_marc('010a')
to_field 'coden_display', extract_marc('030a')

to_field 'standard_no_1display' do |record, accumulator|
  standard_no = standard_no_hash(record)
  accumulator[0] = standard_no.to_json.to_s unless standard_no == {}
end

to_field 'lccn_s', extract_marc('010a') do |record, accumulator|
  accumulator.each_with_index do |value, i|
    accumulator[i] = StdNum::LCCN.normalize(value)
  end
end

to_field 'issn_s', extract_marc('022a') do |record, accumulator|
  accumulator.each_with_index do |value, i|
    accumulator[i] = StdNum::ISSN.normalize(value)
  end
end

to_field 'isbn_s', extract_marc('020a') do |record, accumulator|
  accumulator.each_with_index do |value, i|
    accumulator[i] = StdNum::ISBN.normalize(value)
  end
  accumulator.uniq!
end

to_field 'oclc_s', extract_marc('035a') do |record, accumulator|
  oclcs = []
  accumulator.each_with_index do |value, i|
    oclcs << oclc_normalize(value) if value.start_with?('(OCoLC)')
  end
  accumulator.replace(oclcs.uniq)
end

to_field 'standard_no_index', extract_marc('035a') do |record, accumulator|
  accumulator.each_with_index do |value, i|
    accumulator[i] = remove_parens_035(value)
  end
end

# Other version(s):
#    3500 BBID776W
#    3500 BBID787W
#    3500 776X022A
#    3500 022A776X
#    3500 020A776Z
#    3500 776Z020A
to_field 'other_version_s' do |record, accumulator|
  linked_nums = other_versions(record)
  accumulator.replace(linked_nums)
end



# Original language:
#    880 XX abc
to_field 'original_language_display', extract_marc('880abc')

to_field 'subject_era_facet', marc_era_facet

# # From displayh.cfg

to_field 'holdings_1display' do |record, accumulator|
  all_holdings = process_holdings(record)
  if all_holdings == {}
    logger.error "#{record['001']} - Missing holdings"
  else
    accumulator[0] = all_holdings.to_json.to_s
  end
end

to_field 'location_display', extract_marc('852b', :allow_duplicates => true) do |record, accumulator|
  accumulator = Traject::TranslationMap.new("locations").translate_array!(accumulator)
end

to_field 'location_code_s', extract_marc('852b', :allow_duplicates => true)

to_field 'location', extract_marc('852b', :allow_duplicates => true) do |record, accumulator|
  accumulator = Traject::TranslationMap.new("location_display").translate_array!(accumulator)
  accumulator.delete('Online')
  accumulator.uniq!
end
# # #    1000

to_field 'access_facet', extract_marc('852b', :allow_duplicates => true) do |record, accumulator|
  accumulator = Traject::TranslationMap.new("access", :default => "In the Library").translate_array!(accumulator)
end

# Call number: +No call number available
#    852 XX ckhij
to_field 'call_number_display', extract_marc('852ckhij', :allow_duplicates => true)


to_field 'call_number_browse_s', extract_marc('852khij')


# Location has:
#    1040
#    866 |0 az
#    866 |1 az
#    866 |2 az
#    866 30 az
#    866 31 az
#    866 32 az
#    866 40 az
#    866 41 az
#    866 42 az
#    866 50 az
#    866 51 az
#    866 52 az
#    899 XX a
#to_field 'location_has_display', extract_marc('866| 0|az:866| 1|az:866| 2|az:866|30|az:866|31|az:866|32|az:866|40|az:866|41|az:866|42|az:866|50|az:866|51|az:866|52|az:899a')

# Location has (current):
#    866 || az
#    1020
#to_field 'location_has_current_display', extract_marc('866|  |az')


# Supplements:
#    1042
#    867 XX az
#    1022
#to_field 'supplements_display', extract_marc('867az')


# Indexes:
#    1044
#    868 XX az
#    1024
#to_field 'indexes_display', extract_marc('868az')

########################################################
# Processing already-extracted fields                  #
# Remove holding 856s from electronic_access_1display  #
# and put into holdings_1display                       #
########################################################
each_record do |record, context|
  if context.output_hash['electronic_access_1display']
    bib_856s = JSON.parse(context.output_hash['electronic_access_1display'].first)
    holding_856s = bib_856s.delete('holding_record_856s')
    unless holding_856s.nil?
      holdings_hash = JSON.parse(context.output_hash['holdings_1display'].first)
      holding_856s.each do |h_id, links|
        holdings_hash[h_id]['electronic_access'] = links
      end
      context.output_hash['holdings_1display'][0] = holdings_hash.to_json.to_s
      context.output_hash['electronic_access_1display'][0] = bib_856s.to_json.to_s
    end
  end
  if context.output_hash['location_code_s']
    mapped_codes = Traject::TranslationMap.new("locations")
    context.output_hash['location_code_s'].each do |l|
      logger.error "#{context.output_hash['id'].first} - Invalid Location Code: #{l}" unless mapped_codes[l]
    end
  end
  if context.output_hash['title_display']
    if context.output_hash['title_display'].length > 1
      logger.error "#{context.output_hash['id'].first} - Multiple titles"
      context.output_hash['title_display'] = context.output_hash['title_display'].slice(0,1)
    end
  end
end
