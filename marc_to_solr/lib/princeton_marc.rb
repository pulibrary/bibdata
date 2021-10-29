# encoding: UTF-8
require 'library_stdnums'
require 'lightly'
require 'uri'
require_relative 'cache_adapter'
require_relative 'cache_manager'
require_relative 'cache_map'
require_relative 'composite_cache_map'
require_relative 'electronic_access_link'
require_relative 'electronic_access_link_factory'
require_relative 'iiif_manifest_url_builder'
require_relative 'orangelight_url_builder'

module MARC
  class Record
    # Taken from pul-store marc.rb lib extension
    # Shamelessly lifted from SolrMARC, with a few changes; no doubt there will
    # be more.
    @@THREE_OR_FOUR_DIGITS = /^(20|19|18|17|16|15|14|13|12|11|10|9|8|7|6|5|4|3|2|1)(\d{2})\.?$/
    @@FOUR_DIGIT_PATTERN_BRACES = /^\[([12]\d{3})\??\]\.?$/
    @@FOUR_DIGIT_PATTERN_ONE_BRACE = /^\[(20|19|18|17|16|15|14|13|12|11|10)(\d{2})/
    @@FOUR_DIGIT_PATTERN_OTHER_1 = /^l(\d{3})/
    @@FOUR_DIGIT_PATTERN_OTHER_2 = /^\[(20|19|18|17|16|15|14|13|12|11|10)\](\d{2})/
    @@FOUR_DIGIT_PATTERN_OTHER_3 = /^\[?(20|19|18|17|16|15|14|13|12|11|10)(\d)[^\d]\]?/
    @@FOUR_DIGIT_PATTERN_OTHER_4 = /i\.e\.\,? (20|19|18|17|16|15|14|13|12|11|10)(\d{2})/
    @@FOUR_DIGIT_PATTERN_OTHER_5 = /^\[?(\d{2})\-\-\??\]?/
    @@BC_DATE_PATTERN = /[0-9]+ [Bb]\.?[Cc]\.?/
    def best_date
      date = nil
      if self['260']
        if self['260']['c']
          field_260c = self['260']['c']
          case field_260c
          when @@THREE_OR_FOUR_DIGITS
            date = "#{$1}#{$2}"
          when @@FOUR_DIGIT_PATTERN_BRACES
            date = $1
          when @@FOUR_DIGIT_PATTERN_ONE_BRACE
            date = $1
          when @@FOUR_DIGIT_PATTERN_OTHER_1
            date = "1#{$1}"
          when @@FOUR_DIGIT_PATTERN_OTHER_2
            date = "#{$1}#{$2}"
          when @@FOUR_DIGIT_PATTERN_OTHER_3
            date = "#{$1}#{$2}0"
          when @@FOUR_DIGIT_PATTERN_OTHER_4
            date = "#{$1}#{$2}"
          when @@FOUR_DIGIT_PATTERN_OTHER_5
            date = "#{$1}00"
          when @@BC_DATE_PATTERN
            date = nil
          end
        end
      end
      date ||= self.date_from_008
    end

    def date_from_008
      if self['008']
        d = self['008'].value[7, 4]
        d = d.gsub 'u', '0' unless d == 'uuuu'
        d = d.gsub ' ', '0' unless d == '    '
        d if d =~ /^[0-9]{4}$/
      end
    end

    def end_date_from_008
      if self['008']
        d = self['008'].value[11, 4]
        d = d.gsub 'u', '9' unless d == 'uuuu'
        d = d.gsub ' ', '9' unless d == '    '
        d if d =~ /^[0-9]{4}$/
      end
    end

    def date_display
      date = nil
      if self['260']
        date = self['260']['c'] if self['260']['c']
      end
      date ||= self.date_from_008
    end
  end
end

FALLBACK_STANDARD_NO = 'Other standard number'
def map_024_indicators_to_labels i
  case i
  when '0' then 'International Standard Recording Code'
  when '1' then 'Universal Product Code'
  when '2' then 'International Standard Music Number'
  when '3' then 'International Article Number'
  when '4' then 'Serial Item and Contribution Identifier'
  when '7' then '$2'
  else FALLBACK_STANDARD_NO
  end
end

def indicator_label_246 i
  case i
  when '0' then 'Portion of title'
  when '1' then 'Parallel title'
  when '2' then 'Distinctive title'
  when '3' then 'Other title'
  when '4' then 'Cover title'
  when '5' then 'Added title page title'
  when '6' then 'Caption title'
  when '7' then 'Running title'
  when '8' then 'Spine title'
  end
end

def subfield_specified_hash_key subfield_value, fallback
  key = subfield_value.capitalize.gsub(/[[:punct:]]?$/, '')
  key.empty? ? fallback : key
end

def standard_no_hash record
  standard_no = {}
  Traject::MarcExtractor.cached('024').collect_matching_lines(record) do |field, _spec, _extractor|
    standard_label = map_024_indicators_to_labels(field.indicator1)
    standard_number = nil
    field.subfields.each do |s_field|
      standard_number = s_field.value if s_field.code == 'a'
      standard_label = subfield_specified_hash_key(s_field.value, FALLBACK_STANDARD_NO) if (s_field.code == '2') && (standard_label == '$2')
    end
    standard_label = FALLBACK_STANDARD_NO if standard_label == '$2'
    standard_no[standard_label] ? standard_no[standard_label] << standard_number : standard_no[standard_label] = [standard_number] unless standard_number.nil?
  end
  standard_no
end

# Handles ISBNs, ISSNs, and OCLCs
# ISBN: 020a, 020z, 776z
# ISSN: 022a, 022l, 022y, 022z, 776x
# OCLC: 035a, 776w, 787w
# BIB: 776w, 787w (adds BIB prefix so Blacklight can detect whether to search id field)
def other_versions record
  linked_nums = []
  Traject::MarcExtractor.cached('020az:022alyz:035a:776wxz:787w').collect_matching_lines(record) do |field, _spec, _extractor|
    field.subfields.each do |s_field|
      linked_nums << StdNum::ISBN.normalize(s_field.value) if (field.tag == "020") || ((field.tag == "776") && (s_field.code == 'z'))
      linked_nums << StdNum::ISSN.normalize(s_field.value) if (field.tag == "022") || ((field.tag == "776") && (s_field.code == 'x'))
      linked_nums << oclc_normalize(s_field.value, prefix: true) if (field.tag == "035") && oclc_number?(s_field.value)
      if ((field.tag == "776") && (s_field.code == 'w')) || ((field.tag == "787") && (s_field.code == 'w'))
        linked_nums << oclc_normalize(s_field.value, prefix: true) if oclc_number?(s_field.value)
        linked_nums << "BIB" + strip_non_numeric(s_field.value) unless s_field.value.include?('(')
        logger.error "#{record['001']} - linked field formatting: #{s_field.value}" if s_field.value.include?('(') && !s_field.value.start_with?('(')
      end
    end
  end
  linked_nums.compact.uniq
end

# only includes values before $t
def process_names record
  names = []
  Traject::MarcExtractor.cached('100aqbcdk:110abcdfgkln:111abcdfgklnpq:700aqbcdk:710abcdfgkln:711abcdfgklnpq').collect_matching_lines(record) do |field, spec, extractor|
    name = extractor.collect_subfields(field, spec).first
    unless name.nil?
      remove = ''
      after_t = false
      field.subfields.each do |s_field|
        remove << " #{s_field.value}" if after_t && spec.includes_subfield_code?(s_field.code)
        after_t = true if s_field.code == 't'
      end
      name = name.chomp(remove)
      names << Traject::Macros::Marc21.trim_punctuation(name)
    end
  end
  names.uniq
end

# only includes values before $t
def process_alt_script_names record
  names = []
  Traject::MarcExtractor.cached('100aqbcdk:110abcdfgkln:111abcdfgklnpq:700aqbcdk:710abcdfgkln:711abcdfgklnpq').collect_matching_lines(record) do |field, spec, extractor|
    next unless field.tag == '880'
    name = extractor.collect_subfields(field, spec).first
    unless name.nil?
      remove = ''
      after_t = false
      field.subfields.each do |s_field|
        remove << " #{s_field.value}" if after_t && spec.includes_subfield_code?(s_field.code)
        after_t = true if s_field.code == 't'
      end
      name = name.chomp(remove)
      names << Traject::Macros::Marc21.trim_punctuation(name)
    end
  end
  names.uniq
end

##
# Get hash of authors grouped by role
# @param [MARC::Record]
# @return [Hash]
def process_author_roles record
  author_roles = {
    'TRL' => 'translators',
    'EDT' => 'editors',
    'COM' => 'compilers',
    'TRANSLATOR' => 'translators',
    'EDITOR' => 'editors',
    'COMPILER' => 'compilers'
  }

  names = {}
  names['secondary_authors'] = []
  names['translators'] = []
  names['editors'] = []
  names['compilers'] = []

  Traject::MarcExtractor.cached('100a:110a:111a:700a:710a:711a').collect_matching_lines(record) do |field, spec, extractor|
    name = extractor.collect_subfields(field, spec).first
    unless name.nil?
      name = Traject::Macros::Marc21.trim_punctuation(name)

      # If name is from 1xx field, it is the primary author.
      if /1../.match?(field.tag)
        names['primary_author'] = name
      else
        relator = ""
        field.subfields.each do |s_field|
          # relator code (subfield 4)
          if s_field.code == '4'
            relator = s_field.value.upcase.gsub(/[[:punct:]]?$/, '')
          # relator term (subfield e)
          elsif s_field.code == 'e'
            relator = s_field.value.upcase.gsub(/[[:punct:]]?$/, '')
          end
        end

        # Set role from relator value.
        role = author_roles[relator] || 'secondary_authors'
        names[role] << name
      end
    end
  end
  names
end

##
# Process publication information for citations.
# @param [MARC::Record]
# @return [Array] pub info strings from fields 260 and 264.
def set_pub_citation(record)
  pub_citation = []
  Traject::MarcExtractor.cached('260:264').collect_matching_lines(record) do |field, _spec, _extractor|
    a_pub_info = nil
    b_pub_info = nil
    pub_info = ""
    field.subfields.each do |s_field|
      a_pub_info = Traject::Macros::Marc21.trim_punctuation(s_field.value).strip if s_field.code == 'a'
      b_pub_info = Traject::Macros::Marc21.trim_punctuation(s_field.value).strip if s_field.code == 'b'
    end

    # Build publication info string and add to citation array.
    pub_info += a_pub_info unless a_pub_info.nil?
    pub_info += ": " if !a_pub_info.nil? && !b_pub_info.nil?
    pub_info += b_pub_info unless b_pub_info.nil?
    pub_citation << pub_info if !pub_info.empty?
  end
  pub_citation
end

SEPARATOR = '—'

# for the hierarchical subject/genre display
# split with em dash along t,v,x,y,z
# optional vocabulary argument for allowing certain subfield $2 vocabularies
def process_hierarchy(record, fields, vocabulary = [])
  headings = []
  split_on_subfield = ['t', 'v', 'x', 'y', 'z']
  Traject::MarcExtractor.cached(fields).collect_matching_lines(record) do |field, spec, extractor|
    heading = extractor.collect_subfields(field, spec).first
    include_heading = vocabulary.empty? # always include the heading if a vocabulary is not specified
    unless heading.nil?
      field.subfields.each do |s_field|
        # when specified, only include heading if it is part of the vocabulary
        include_heading = vocabulary.include?(s_field.value) if s_field.code == '2' && !vocabulary.empty?
        heading = heading.gsub(" #{s_field.value}", "#{SEPARATOR}#{s_field.value}") if split_on_subfield.include?(s_field.code)
      end
      heading = heading.split(SEPARATOR)
      heading = heading.map { |s| Traject::Macros::Marc21.trim_punctuation(s) }.join(SEPARATOR)
      headings << heading if include_heading
    end
  end
  headings
end

# for the split subject facet
# split with em dash along x,z
def process_subject_topic_facet record
  subjects = []
  Traject::MarcExtractor.cached('600|*0|abcdfklmnopqrtxz:610|*0|abfklmnoprstxz:611|*0|abcdefgklnpqstxz:630|*0|adfgklmnoprstxz:650|*0|abcxz:651|*0|axz').collect_matching_lines(record) do |field, spec, extractor|
    subject = extractor.collect_subfields(field, spec).first
    unless subject.nil?
      field.subfields.each do |s_field|
        subject = subject.gsub(" #{s_field.value}", "#{SEPARATOR}#{s_field.value}") if (s_field.code == 'x' || s_field.code == 'z')
      end
      subject = subject.split(SEPARATOR)
      subjects << subject.map { |s| Traject::Macros::Marc21.trim_punctuation(s) }
    end
  end
  Traject::MarcExtractor.cached('650|*7|abcxz').collect_matching_lines(record) do |field, spec, extractor|
    subject = extractor.collect_subfields(field, spec).first
    should_include = false
    unless subject.nil?
      field.subfields.each do |s_field|
        should_include = s_field.value == 'sk' if s_field.code == '2'
        subject = subject.gsub(" #{s_field.value}", "#{SEPARATOR}#{s_field.value}") if (s_field.code == 'x' || s_field.code == 'z')
      end
      subject = subject.split(SEPARATOR)
      subjects << subject.map { |s| Traject::Macros::Marc21.trim_punctuation(s) } if should_include
    end
  end
  subjects.flatten
end

def strip_non_numeric num_str
  num_str.gsub(/\D/, '').to_i.to_s
end

def oclc_number? oclc
  # Strip spaces and dashes
  clean_oclc = oclc.gsub(/[\-\s]/, '')
  # Ensure it follows the OCLC standard
  # (see https://help.oclc.org/Metadata_Services/WorldShare_Collection_Manager/Data_sync_collections/Prepare_your_data/30035_field_and_OCLC_control_numbers)
  clean_oclc.match(/\(OCoLC\)(ocn|ocm|on)*\d+/) != nil
end

def oclc_normalize oclc, opts = { prefix: false }
  oclc_num = strip_non_numeric(oclc)
  if opts[:prefix] == true
    case oclc_num.length
    when 1..8
      "ocm" + "%08d" % oclc_num
    when 9
      "ocn" + oclc_num
    else
      "on" + oclc_num
    end
  else
    oclc_num
  end
end

# Construct (or retrieve) the cache manager service
# @return [CacheManager] the cache manager service
def build_cache_manager(figgy_dir_path:)
  return @cache_manager unless @cache_manager.nil?

  figgy_lightly = Lightly.new(dir: figgy_dir_path, life: 0, hash: false)
  figgy_cache_adapter = CacheAdapter.new(service: figgy_lightly)

  CacheManager.initialize(figgy_cache: figgy_cache_adapter, logger: logger)

  @cache_manager = CacheManager.current
end

# returns hash of links ($u) (key),
# anchor text ($y, $3, hostname), and additional labels ($z) (array value)
# @param [MARC::Record] the MARC record being parsed
# @return [Hash] the values used to construct the links
def electronic_access_links(record, figgy_dir_path)
  solr_field_values = {}
  holding_856s = {}
  iiif_manifest_paths = {}

  output = []
  iiif_manifest_links = []
  fragment_index = 0

  Traject::MarcExtractor.cached('856').collect_matching_lines(record) do |field, _spec, _extractor|
    anchor_text = false
    z_label = false
    url_key = false
    holding_id = nil
    bib_id = record['001']

    electronic_access_link = ElectronicAccessLinkFactory.build bib_id: bib_id, marc_field: field

    # If the electronic access link is an ARK...
    if electronic_access_link.ark
      # ...and attempt to build an Orangelight URL from the (cached) mappings exposed by the repositories
      cache_manager = build_cache_manager(figgy_dir_path: figgy_dir_path)

      # Orangelight links
      catalog_url_builder = OrangelightUrlBuilder.new(ark_cache: cache_manager.ark_cache, fragment: fragment_value(fragment_index))
      orangelight_url = catalog_url_builder.build(url: electronic_access_link.ark)

      if orangelight_url
        # Index this by the domain for Orangelight
        anchor_text = electronic_access_link.anchor_text
        anchor_text = 'Digital content' if electronic_access_link.url&.host == electronic_access_link.anchor_text
        orangelight_link = electronic_access_link.clone url_key: orangelight_url.to_s, anchor_text: anchor_text
        # Only add the link to the current page if it resolves to a resource with a IIIF Manifest
        output << orangelight_link
      else
        # Otherwise, always add the link to the resource
        output << electronic_access_link
      end

      # Figgy URL's
      figgy_url_builder = IIIFManifestUrlBuilder.new(ark_cache: cache_manager.figgy_ark_cache, service_host: 'figgy.princeton.edu')
      figgy_iiif_manifest = figgy_url_builder.build(url: electronic_access_link.ark)
      if figgy_iiif_manifest
        figgy_iiif_manifest_link = electronic_access_link.clone url_key: figgy_iiif_manifest.to_s
        iiif_manifest_paths[electronic_access_link.url_key] = figgy_iiif_manifest_link.url.to_s
      end

    else
      # Always add links to the resource if it isn't an ARK
      output << electronic_access_link
    end

    output.each do |link|
      if link.holding_id
        holding_856s[link.holding_id] = { link.url_key => link.url_labels }
      elsif link.url_key && link.url_labels
        solr_field_values[link.url_key] = link.url_labels
      end
    end
    fragment_index += 1
  end

  solr_field_values['holding_record_856s'] = holding_856s unless holding_856s == {}
  solr_field_values['iiif_manifest_paths'] = iiif_manifest_paths unless iiif_manifest_paths.empty?
  solr_field_values
end

def fragment_value(fragment_index)
  if fragment_index == 0
    'view'
  else
    "view_#{fragment_index}"
  end
end

def remove_parens_035 standard_no
  standard_no.gsub(/^\(.*?\)/, '')
end

GENRES = [
  'Bibliography',
  'Biography',
  'Catalogs',
  'Catalogues raisonnes',
  'Commentaries',
  'Congresses',
  'Diaries',
  'Dictionaries',
  'Drama',
  'Encyclopedias',
  'Exhibitions',
  'Fiction',
  'Guidebooks',
  'In art',
  'Indexes',
  'Librettos',
  'Manuscripts',
  'Newspapers',
  'Periodicals',
  'Pictorial works',
  'Poetry',
  'Portraits',
  'Scores',
  'Songs and music',
  'Sources',
  'Statistics',
  'Texts',
  'Translations'
]

GENRE_STARTS_WITH = [
  'Census',
  'Maps',
  'Methods',
  'Parts',
  'Personal narratives',
  'Scores and parts',
  'Study and teaching',
  'Translations into '
]

SUBJECT_GENRE_VOCABULARIES = ['sk', 'aat', 'lcgft', 'rbbin', 'rbgenr', 'rbmscv',
                              'rbpap', 'rbpri', 'rbprov', 'rbpub', 'rbtyp']

# 600/610/650/651 $v, $x filtered
# 655 $a, $v, $x filtered
def process_genre_facet record
  genres = []
  Traject::MarcExtractor.cached('600|*0|x:610|*0|x:611|*0|x:630|*0|x:650|*0|x:651|*0|x:655|*0|x').collect_matching_lines(record) do |field, spec, extractor|
    genre = extractor.collect_subfields(field, spec).first
    unless genre.nil?
      genre = Traject::Macros::Marc21.trim_punctuation(genre)
      genres << genre if GENRES.include?(genre) || GENRE_STARTS_WITH.any? { |g| genre[g] }
    end
  end
  Traject::MarcExtractor.cached('650|*7|v:655|*7|a:655|*7|v').collect_matching_lines(record) do |field, spec, extractor|
    should_include = false
    field.subfields.each do |s_field|
      # only include heading if it is part of the vocabulary
      should_include = SUBJECT_GENRE_VOCABULARIES.include?(s_field.value) if s_field.code == '2'
    end
    genre = extractor.collect_subfields(field, spec).first
    unless genre.nil?
      genre = Traject::Macros::Marc21.trim_punctuation(genre)
      if genre.match?(/^\s+$/)
        logger.error "#{record['001']} - Blank genre field"
      elsif should_include
        genres << genre
      end
    end
  end
  Traject::MarcExtractor.cached('600|*0|v:610|*0|v:611|*0|v:630|*0|v:650|*0|v:651|*0|v:655|*0|a:655|*0|v').collect_matching_lines(record) do |field, spec, extractor|
    genre = extractor.collect_subfields(field, spec).first
    unless genre.nil?
      genre = Traject::Macros::Marc21.trim_punctuation(genre)
      if genre.match?(/^\s+$/)
        logger.error "#{record['001']} - Blank genre field"
      else
        genres << genre
      end
    end
  end
  genres.uniq
end

def everything_after_t record, fields
  values = []
  Traject::MarcExtractor.cached(fields).collect_matching_lines(record) do |field, _spec, _extractor|
    after_t = false
    title = []
    field.subfields.each do |s_field|
      title << s_field.value if after_t
      if s_field.code == 't'
        title << s_field.value
        after_t = true
      end
    end
    values << Traject::Macros::Marc21.trim_punctuation(title.join(' ')) unless title.empty?
  end
  values
end

def everything_after_t_alt_script record, fields
  values = []
  Traject::MarcExtractor.cached(fields).collect_matching_lines(record) do |field, _spec, _extractor|
    next unless field.tag == '880'
    after_t = false
    title = []
    field.subfields.each do |s_field|
      title << s_field.value if after_t
      if s_field.code == 't'
        title << s_field.value
        after_t = true
      end
    end
    values << Traject::Macros::Marc21.trim_punctuation(title.join(' ')) unless title.empty?
  end
  values
end

def everything_through_t record, fields
  values = []
  Traject::MarcExtractor.cached(fields).collect_matching_lines(record) do |field, _spec, _extractor|
    non_t = true
    title = []
    field.subfields.each do |s_field|
      title << s_field.value
      if s_field.code == 't'
        non_t = false
        break
      end
    end
    values << Traject::Macros::Marc21.trim_punctuation(title.join(' ')) unless (title.empty? || non_t)
  end
  values
end

##
# @param record [MARC::Record]
# @param fields [String] MARC fields of interest
# @return [Array] of name-titles each in an [Array], each element [String] split by hierarchy,
# both name ($a) and title ($t) are required
def prep_name_title record, fields
  values = []
  Traject::MarcExtractor.cached(fields).collect_matching_lines(record) do |field, spec, _extractor|
    name_title = []
    author = []
    non_a = true
    non_t = true
    field.subfields.each do |s_field|
      next if (!spec.subfields.nil? && !spec.subfields.include?(s_field.code))
      non_a = false if s_field.code == 'a'
      non_t = false if s_field.code == 't'
      if non_t
        author << s_field.value
      else
        name_title << s_field.value
      end
    end
    unless (non_a || non_t)
      name_title.unshift(author.join(' '))
      values << name_title unless name_title.empty?
    end
  end
  values
end

# @param fields [Array] with portions of hierarchy from name-titles
# @return [Array] name-title portions of hierarchy including previous elements, author
def join_hierarchy_without_author fields
  fields.collect { |h| h.collect.with_index { |_v, i| Traject::Macros::Marc21.trim_punctuation(h[0..i].join(' ')) } }
end

# @param fields [Array] with portions of hierarchy from name-titles
# @return [Array] name-title portions of hierarchy including previous elements
def join_hierarchy fields
  join_hierarchy_without_author(fields).map { |a| a[1..-1] }
end

# Removes empty call_number fields from holdings_1display
def remove_empty_call_number_fields(holding)
  holding.tap { |h| ["call_number", "call_number_browse"].map { |k| h.delete(k) if h.fetch(k, []).empty? } }
end

# Collects only non empty khi
def call_number_khi(field)
  field.subfields.reject { |s| s.value.empty? }.collect { |s| s if ["k", "h", "i"].include?(s.code) }.compact
end

# Alma Princeton item
def alma_code_start_22?(code)
  code.to_s.start_with?("22") && code.to_s.end_with?("06421")
end

def alma_code_start_53?(code)
  code.to_s.start_with?("53") && code.to_s.end_with?("06421")
end

def alma_852(record)
  record.fields('852').select { |f| alma_code_start_22?(f['8']) }
end

def scsb_852(record)
  record.fields('852').select { |f| scsb_doc?(record['001'].value) && f['0'] }
end

def alma_876(record)
  record.fields('876').select { |f| alma_code_start_22?(f['0']) }
end

def alma_951_active(record)
  alma_951 = record.fields('951').select { |f| alma_code_start_53?(f['8']) }
  alma_951&.select { |f| f['a'] == "Available" }
end

def alma_953(record)
  record.fields('953').select { |f| alma_code_start_53?(f['a']) }
end

def alma_954(record)
  record.fields('954').select { |f| alma_code_start_53?(f['a']) }
end

def alma_950(record)
  field_950_a = record.fields('950').select { |f| ["true", "false"].include?(f['a']) }
  field_950_a.map { |f| f['b'] }.first if field_950_a.present?
end

# SCSB item
# Keep this check with the alma_code? check
# until we make sure that the records in alma are updated
def scsb_doc?(record_id)
  /^SCSB-\d+/.match?(record_id)
end

def group_866_867_868_on_holding_perm_id(record, holding_perm_id, is_scsb)
  if is_scsb
    record.fields("866".."868").select { |f| f["0"] == holding_perm_id }
  else
    record.fields("866".."868").select { |f| f["8"] == holding_perm_id }
  end
end

def group_867_on_holding_perm_id(record, holding_perm_id)
  record.fields("867").select { |f| f["8"] == holding_perm_id }
end

def group_868_on_holding_perm_id(record, holding_perm_id)
  record.fields("868").select { |f| f["8"] == holding_perm_id }
end

def group_876_on_holding_perm_id(record, holding_id)
  record.fields("876").select { |f| f["0"] == holding_id }
end

# get 852 fields from an ALma or SCSB record
def fields_852_alma_or_scsb(record)
  record.fields('852').select do |f|
    alma_code_start_22?(f['8']) || scsb_doc?(record['001'].value) && f['0']
  end
end

def current_location_code(field_876)
  "#{field_876['y']}$#{field_876['z']}" if field_876['y'] && field_876['z']
end

def permanent_location_code(field_852)
  "#{field_852['b']}$#{field_852['c']}"
end

def select_permanent_location_876(group_876_fields, field_852)
  return group_876_fields if /^scsb/.match?(field_852['b'])
  group_876_fields.select { |field_876| current_location_code(field_876) == permanent_location_code(field_852) }
end

def select_current_location_876(group_876_fields, field_852)
  return [] if /^scsb/.match?(field_852['b'])
  group_876_fields.select { |field_876| current_location_code(field_876) != permanent_location_code(field_852) }
end

def current_holding(holding_current, field_852, field_876)
  holding_current["location_code"] ||= current_location_code(field_876)
  holding_current['current_location'] ||= Traject::TranslationMap.new("locations", default: "__passthrough__")[holding_current['location_code']]
  holding_current['current_library'] ||= Traject::TranslationMap.new("location_display", default: "__passthrough__")[holding_current['location_code']]
  holding_current['call_number'] ||= []
  holding_current['call_number'] << [field_852['h'], field_852['i'], field_852['k'], field_852['j']].compact.reject(&:empty?)
  holding_current['call_number'].flatten!
  holding_current['call_number'] = holding_current['call_number'].join(' ').strip if holding_current['call_number'].present?
  holding_current['call_number_browse'] ||= []
  holding_current['call_number_browse'] << [field_852['h'], field_852['i'], field_852['k'], field_852['j']].compact.reject(&:empty?)
  holding_current['call_number_browse'].flatten!
  holding_current['call_number_browse'] = holding_current['call_number_browse'].join(' ').strip if holding_current['call_number_browse'].present?
  # Updates current holding key; values are from 852
  if field_852['l']
    holding_current['shelving_title'] ||= []
    holding_current['shelving_title'] << field_852['l']
  end
  if field_852['z']
    holding_current['location_note'] ||= []
    holding_current['location_note'] << field_852['z']
  end
  holding_current
end

def permanent_holding(holding, field_852)
  is_alma = alma_code_start_22?(field_852['8'])
  holding['location_code'] ||= field_852['b']
  # Append 852c to location code 852b if it's an Alma item
  # Do not append the 852c if it is a SCSB - we save the SCSB locations as scsbnypl and scsbcul
  holding['location_code'] += "$#{field_852['c']}" if field_852['c'] && is_alma
  holding['location'] ||= Traject::TranslationMap.new("locations", default: "__passthrough__")[holding['location_code']]
  holding['library'] ||= Traject::TranslationMap.new("location_display", default: "__passthrough__")[holding['location_code']]
  # calculate call_number for permanent location
  holding['call_number'] ||= []
  holding['call_number'] << [field_852['h'], field_852['i'], field_852['k'], field_852['j']].compact.reject(&:empty?)
  holding['call_number'].flatten!
  holding['call_number'] = holding['call_number'].join(' ').strip if holding['call_number'].present?
  holding['call_number_browse'] ||= []
  holding['call_number_browse'] << [field_852['h'], field_852['i'], field_852['k'], field_852['j']].compact.reject(&:empty?)
  holding['call_number_browse'].flatten!
  holding['call_number_browse'] = holding['call_number_browse'].join(' ').strip if holding['call_number_browse'].present?
  if field_852['l']
    holding['shelving_title'] ||= []
    holding['shelving_title'] << field_852['l']
  end
  if field_852['z']
    holding['location_note'] ||= []
    holding['location_note'] << field_852['z']
  end
  holding
end

# build the items array in all_holdings hash
def holding_items(value:, all_holdings:, item:)
  if all_holdings[value].present?
    if all_holdings[value]["items"].nil?
      all_holdings[value]["items"] = [item]
    else
      all_holdings[value]["items"] << item
    end
  end
  all_holdings
end

def build_item(record:, item:, field_852:, field_876:)
  is_scsb = scsb_doc?(record['001'].value) && field_852['0']
  item[:holding_id] = field_876['0'] if field_876['0']
  item[:enumeration] = field_876['3'] if field_876['3']
  item[:id] = field_876['a'] if field_876['a']
  item[:status_at_load] = field_876['j'] if field_876['j']
  item[:barcode] = field_876['p'] if field_876['p']
  item[:copy_number] = field_876['t'] if field_876['t']
  item[:use_statement] = field_876['h'] if field_876['h'] && is_scsb
  item[:storage_location] = field_876['l'] if field_876['l'] && is_scsb
  item[:cgc] = field_876['x'] if field_876['x'] && is_scsb
  item[:collection_code] = field_876['z'] if field_876['z'] && is_scsb
  item
end

def process_866_867_868_fields(fields:, all_holdings:, holding_id:)
  fields.each do |field|
    location_has_value = []
    supplements_value = []
    indexes_value = []
    location_has_value << field['a'] if field.tag == '866' && field['a']
    location_has_value << field['z'] if field.tag == '866' && field['z']
    supplements_value << field['a'] if field.tag == '867' && field['a']
    supplements_value << field['z'] if field.tag == '867' && field['z']
    indexes_value << field['a'] if field.tag == '868' && field['a']
    indexes_value << field['z'] if field.tag == '868' && field['z']
    if all_holdings[holding_id]
      all_holdings[holding_id]['location_has'] ||= []
      all_holdings[holding_id]['supplements'] ||= []
      all_holdings[holding_id]['indexes'] ||= []
      all_holdings[holding_id]['location_has'] << location_has_value.join(' ') if location_has_value.present?
      all_holdings[holding_id]['supplements'] << supplements_value.join(' ') if supplements_value.present?
      all_holdings[holding_id]['indexes'] << indexes_value.join(' ') if indexes_value.present?
    end
  end
  all_holdings
end

def process_holdings(record)
  all_holdings = {}
  fields_852_alma_or_scsb(record).each do |field_852|
    holding = {}
    is_alma = alma_code_start_22?(field_852['8'])
    is_scsb = scsb_doc?(record['001'].value) && field_852['0']
    if field_852['8'] && is_alma
      holding_id = field_852['8']
    elsif field_852['0'] && is_scsb
      holding_id = field_852['0']
    end
    permanent_holding(holding, field_852)
    group_876_fields = group_876_on_holding_perm_id(record, holding_id)
    group_866_867_868_fields = group_866_867_868_on_holding_perm_id(record, holding_id, is_scsb)
    permanent_location_876 = select_permanent_location_876(group_876_fields, field_852)
    current_location_876 = select_current_location_876(group_876_fields, field_852)
    if group_876_fields.present?
      permanent_location_876.each do |field_876|
        item = {}
        build_item(record: record, item: item, field_852: field_852, field_876: field_876)
        all_holdings[holding_id] = remove_empty_call_number_fields(holding) unless holding_id.nil? || invalid_location?(holding['location_code'])
        # Adds items in permanent location where the key is the holding_id from 852.
        holding_items(value: item[:holding_id], all_holdings: all_holdings, item: item)
      end
      current_location_876.each do |field_876|
        item_current = {}
        holding_current = {}
        holding_current_id = current_location_code(field_876)
        current_holding(holding_current, field_852, field_876)
        build_item(record: record, item: item_current, field_852: field_852, field_876: field_876)
        all_holdings[holding_current_id] = remove_empty_call_number_fields(holding_current) if all_holdings[holding_current_id].nil? && !(holding_current_id.nil? || invalid_location?(holding_current['location_code']))

        # Adds items in temporary location where the key is the current (temporary) location code.
        holding_items(value: holding_current_id, all_holdings: all_holdings, item: item_current)
      end
    else
      # if there are no 876s (items) create the holding by using the 852 field
      all_holdings[holding_id] = remove_empty_call_number_fields(holding) unless holding_id.nil? || invalid_location?(holding['location_code'])
    end
    process_866_867_868_fields(fields: group_866_867_868_fields, all_holdings: all_holdings, holding_id: holding_id)
  end
  all_holdings
end

def invalid_location?(code)
  Traject::TranslationMap.new("locations")[code].nil?
end

def process_recap_notes record
  item_notes = []
  partner_lib = nil
  Traject::MarcExtractor.cached('852').collect_matching_lines(record) do |field, _spec, _extractor|
    is_scsb = scsb_doc?(record['001'].value) && field['0']
    next unless is_scsb
    field.subfields.each do |s_field|
      if s_field.code == 'b'
        partner_lib = s_field.value # ||= Traject::TranslationMap.new("locations", :default => "__passthrough__")[s_field.value]
      end
    end
  end
  Traject::MarcExtractor.cached('87603ahjptxz').collect_matching_lines(record) do |field, _spec, _extractor|
    is_scsb = scsb_doc?(record['001'].value) && field['0']
    next unless is_scsb
    col_group = ''
    field.subfields.each do |s_field|
      if s_field.code == 'x'
        if s_field.value == 'Shared'
          col_group = 'S'
        elsif s_field.value == 'Private'
          col_group = 'P'
        elsif s_field.value == 'Committed'
          col_group = 'C'
        elsif s_field.value == 'Uncommittable'
          col_group = 'U'
        else
          col_group = 'O'
        end
      end
    end
    if partner_lib == 'scsbnypl'
      partner_display_string = 'N'
    elsif partner_lib == 'scsbcul'
      partner_display_string = 'C'
    elsif partner_lib == "scsbhl"
      partner_display_string = "H"
    end
    item_notes << "#{partner_display_string} - #{col_group}"
  end
  item_notes
end

def find_hathi_by_oclc(oclc)
  return if ENV["RUN_HATHI_COMPARE"].blank?
  output_dir = ENV['HATHI_OUTPUT_DIR']
  if output_dir.blank?
    puts "The output directory must be set for Hathi comparison to work!!! ENV['HATHI_OUTPUT_DIR']"
    return ""
  end
  overlap_file = Dir.glob("#{output_dir}/overlap*final.tsv").sort_by { |filename| filename.to_date.strftime }.last
  if overlap_file.blank?
    puts "The overlap file is missing from #{output_dir}!!"
    return ""
  end
  oclc_hathi = `grep "^#{oclc}\t" #{overlap_file}`
end

# "980\t1590302\tmono\tdeny\tic\tmdp.39015002162876\n980\t1590302\tmono\tdeny\tic\tmdp.39015010651894\n980\t1590302\tmono\tdeny\tic\tmdp.39015066013585\n"
def parse_locations_from_hathi_line(line)
  return [] if line.blank?
  access = line.split("\t")[3]
  locs = ["hathi"]
  locs << "hathi_temp" if access == "deny"
  locs
end

def parse_hathi_identifer_from_hathi_line(line)
  return "" if line.blank?
  [line.split("\n").first.split("\t")[5]]
end
