require 'active_support'
require 'library_standard_numbers'
require 'lightly'
require 'uri'
require_relative 'cache_adapter'
require_relative 'cache_manager'
require_relative 'cache_map'
require_relative 'composite_cache_map'
require_relative 'electronic_access_link'
require_relative 'electronic_access_link_factory'
require_relative 'hierarchical_heading'
require_relative 'iiif_manifest_url_builder'
require_relative 'linked_fields_extractor'
require_relative 'orangelight_url_builder'
require_relative 'process_holdings_helpers'

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
    @@FOUR_DIGIT_PATTERN_OTHER_4 = /i\.e\.,? (20|19|18|17|16|15|14|13|12|11|10)(\d{2})/
    @@FOUR_DIGIT_PATTERN_OTHER_5 = /^\[?(\d{2})--\??\]?/
    @@BC_DATE_PATTERN = /[0-9]+ [Bb]\.?[Cc]\.?/
    def best_date
      date = nil
      if self['260'] && (self['260']['c'])
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
      date ||= self.date_from_008
    end

    def date_from_008
      if self['008']
        d = self['008'].value[7, 4]
        d = d.tr 'u', '0' unless d == 'uuuu'
        d = d.tr ' ', '0' unless d == '    '
        d if /^[0-9]{4}$/.match?(d)
      end
    end

    def end_date_from_008
      if self['008']
        d = self['008'].value[11, 4]
        d = d.tr 'u', '9' unless d == 'uuuu'
        d = d.tr ' ', '9' unless d == '    '
        d if /^[0-9]{4}$/.match?(d)
      end
    end

    def date_display
      date = nil
      date = self['260']['c'] if self['260'] && (self['260']['c'])
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
      if (s_field.code == '2') && (standard_label == '$2')
        standard_label = subfield_specified_hash_key(s_field.value, FALLBACK_STANDARD_NO)
      end
    end
    standard_label = FALLBACK_STANDARD_NO if standard_label == '$2'
    unless standard_number.nil?
      standard_no[standard_label] ? standard_no[standard_label] << standard_number : standard_no[standard_label] = [standard_number]
    end
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
      if (field.tag == '020') || ((field.tag == '776') && (s_field.code == 'z'))
        linked_nums << LibraryStandardNumbers::ISBN.normalize(s_field.value)
      end
      if (field.tag == '022') || ((field.tag == '776') && (s_field.code == 'x'))
        linked_nums << LibraryStandardNumbers::ISSN.normalize(s_field.value)
      end
      linked_nums << oclc_normalize(s_field.value, prefix: true) if (field.tag == '035') && oclc_number?(s_field.value)
      if ((field.tag == '776') && (s_field.code == 'w')) || ((field.tag == '787') && (s_field.code == 'w'))
        linked_nums << oclc_normalize(s_field.value, prefix: true) if oclc_number?(s_field.value)
        linked_nums << ('BIB' + strip_non_numeric(s_field.value)) unless s_field.value.include?('(')
        if s_field.value.include?('(') && !s_field.value.start_with?('(')
          logger.error "#{record['001']} - linked field formatting: #{s_field.value}"
        end
      end
    end
  end
  linked_nums.compact.uniq
end

# only includes values before $t
def process_names record
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
      Traject::Macros::Marc21.trim_punctuation(name)
    end
  end.compact.uniq
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
        relator = ''
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
  Traject::MarcExtractor.cached('260:264').collect_matching_lines(record) do |field, _spec, _extractor|
    a_pub_info = nil
    b_pub_info = nil
    pub_info = ''
    field.subfields.each do |s_field|
      a_pub_info = Traject::Macros::Marc21.trim_punctuation(s_field.value).strip if s_field.code == 'a'
      b_pub_info = Traject::Macros::Marc21.trim_punctuation(s_field.value).strip if s_field.code == 'b'
    end

    # Build publication info string and add to citation array.
    pub_info += a_pub_info unless a_pub_info.nil?
    pub_info += ': ' if !a_pub_info.nil? && !b_pub_info.nil?
    pub_info += b_pub_info unless b_pub_info.nil?
    pub_info if !pub_info.empty?
  end.compact
end

SEPARATOR = '—'

# for the hierarchical subject/genre display
# split with em dash along t,v,x,y,z
# optionally pass a block to only allow fields that match certain criteria
# For example, if you only want subject headings from the Bilindex vocabulary,
# you could use `process_hierarchy(record, '650|*7|abcvxyz') { |field| field['2'] == 'bidex' }`
def process_hierarchy(record, fields)
  split_on_subfield = %w[t v x y z]
  Traject::MarcExtractor.cached(fields).collect_matching_lines(record) do |field, spec, extractor|
    include_heading = block_given? ? yield(field) : true
    next unless include_heading && extractor.collect_subfields(field, spec).first

    HierarchicalHeading.new(field:, spec:, split_on_subfield:).to_s
  end.compact
end

def accumulate_hierarchy_per_field(record, fields)
  split_on_subfield = %w[t v x y z]
  Traject::MarcExtractor.cached(fields).collect_matching_lines(record) do |field, spec, extractor|
    include_heading = block_given? ? yield(field) : true
    next unless include_heading && extractor.collect_subfields(field, spec).first

    hierarchical_heading = HierarchicalHeading.new(field:, spec:, split_on_subfield:).to_s

    heading_split_on_separator = hierarchical_heading.split(SEPARATOR)
    accumulate_subheading(heading_split_on_separator)
  end.compact
end

def accumulate_subheading(heading_split_on_separator)
  heading_split_on_separator.reduce([]) do |accumulator, subheading|
    # accumulator.last ? "#{accumulator.last}#{SEPARATOR}#{subsubject}" : subsubject
    accumulator.append([accumulator.last, subheading].compact.join(SEPARATOR))
  end
end

# for the split subject facet
# split with em dash along x,z
def process_subject_topic_facet record
  lcsh_subjects = Traject::MarcExtractor.cached('600|*0|abcdfklmnopqrtxz:610|*0|abfklmnoprstxz:611|*0|abcdefgklnpqstxz:630|*0|adfgklmnoprstxz:650|*0|abcxz:651|*0|axz').collect_matching_lines(record) do |field, spec, extractor|
    subject = extractor.collect_subfields(field, spec).first
    unless subject.nil?
      hierarchical_string = HierarchicalHeading.new(field:, spec:, split_on_subfield: %w[x z]).to_s
      hierarchical_string.split(SEPARATOR)
    end
  end.compact
  other_thesaurus_subjects = Traject::MarcExtractor.cached('650|*7|abcxz').collect_matching_lines(record) do |field, spec, extractor|
    subject = extractor.collect_subfields(field, spec).first
    should_include = siku_heading?(field) || local_heading?(field) || any_thesaurus_match?(field, %w[homoit])
    if should_include && !subject.nil?
      hierarchical_string = HierarchicalHeading.new(field:, spec:, split_on_subfield: %w[x z]).to_s
      hierarchical_string.split(SEPARATOR)
    end
  end.flatten.compact
  lcsh_subjects + other_thesaurus_subjects
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
      'ocm' + ('%08d' % oclc_num)
    when 9
      'ocn' + oclc_num
    else
      'on' + oclc_num
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

  CacheManager.initialize(figgy_cache: figgy_cache_adapter, logger:)

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
      cache_manager = build_cache_manager(figgy_dir_path:)

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

# @param fields [Array] with portions of hierarchy
# @return [Array] portions of hierarchy including previous elements
def expand_sublists_for_hierarchy(fields)
  fields.collect do |field|
    field.collect.with_index do |_v, index|
      Traject::Macros::Marc21.trim_punctuation(field[0..index].join(' '))
    end
  end
end

# @param fields [Array] with portions of hierarchy from name-titles or title-only fields
# @return [Array] portions of hierarchy including previous elements
def join_hierarchy(fields, include_first_element: false)
  if include_first_element == false
    # Exclude the name-only portion of hierarchy
    expand_sublists_for_hierarchy(fields).map { |a| a[1..-1] }
  else
    # Include full hierarchy
    expand_sublists_for_hierarchy(fields)
  end
end

# Removes empty call_number fields from holdings_1display
def remove_empty_call_number_fields(holding)
  holding.tap { |h| %w[call_number call_number_browse].map { |k| h.delete(k) if h.fetch(k, []).empty? } }
end

# Collects only non empty khi
def call_number_khi(field)
  field.subfields.reject { |s| s.value.empty? }.collect { |s| s if %w[k h i].include?(s.code) }.compact
end

# Alma Princeton item
def alma_code_start_22?(code)
  code.to_s.start_with?('22') && code.to_s.end_with?('06421')
end

def alma_code_start_53?(code)
  code.to_s.start_with?('53') && code.to_s.end_with?('06421')
end

def scsb_code_start?(code)
  code.to_s.start_with?('scsb')
end

def alma_852(record)
  record.fields('852').select { |f| alma_code_start_22?(f['8']) }
end

def scsb_852(record)
  record.fields('852').select { |f| scsb_code_start?(f['b']) }
end

def browse_fields(record, khi_key_order: %w[k h i])
  result = []
  fields = if scsb_doc?(record['001']&.value)
             scsb_852(record)
           else
             alma_852(record)
           end
  fields.each do |field|
    subfields = call_number_khi(field)
    next if subfields.empty?

    values = [field[khi_key_order[0]], field[khi_key_order[1]], field[khi_key_order[2]]].compact.reject(&:empty?)
    result << values.join(' ') if values.present?
  end
  result
end

def alma_876(record)
  record.fields('876').select { |f| alma_code_start_22?(f['0']) }
end

def alma_951_active(record)
  alma_951 = record.fields('951').select { |f| alma_code_start_53?(f['8']) }
  alma_951&.select { |f| f['a'] == 'Available' }
end

def alma_953(record)
  record.fields('953').select { |f| alma_code_start_53?(f['a']) }
end

def alma_954(record)
  record.fields('954').select { |f| alma_code_start_53?(f['a']) }
end

def alma_950(record)
  field_950_a = record.fields('950').select { |f| %w[true false].include?(f['a']) }
  field_950_a.map { |f| f['b'] }.first if field_950_a.present?
end

# SCSB item
# Keep this check with the alma_code? check
# until we make sure that the records in alma are updated
def scsb_doc?(record_id)
  /^SCSB-\d+/.match?(record_id)
end

def process_holdings(record)
  all_holdings = {}
  holdings_helpers = ProcessHoldingsHelpers.new(record:)
  holdings_helpers.fields_852_alma_or_scsb.each do |field_852|
    next if holdings_helpers.includes_only_private_scsb_items?(field_852)

    holding_id = holdings_helpers.holding_id(field_852)
    # Calculate the permanent holding
    holding = holdings_helpers.build_holding(field_852, permanent: true)
    items_by_holding = holdings_helpers.items_by_852(field_852)
    group_866_867_868_fields = holdings_helpers.group_866_867_868_on_holding_perm_id(holding_id, field_852)
    # if there are items (876 fields)
    if items_by_holding.present?
      add_permanent_items_to_holdings(items_by_holding, field_852, holdings_helpers, all_holdings, holding)
      add_temporary_items_to_holdings(items_by_holding, field_852, holdings_helpers, all_holdings)
    else
      # if there are no items (876 fields), create the holding by using the 852 field
      unless holding_id.nil? || invalid_location?(holding['location_code'])
        all_holdings[holding_id] = remove_empty_call_number_fields(holding)
      end
    end
    if all_holdings.present? && all_holdings[holding_id]
      all_holdings = holdings_helpers.process_866_867_868_fields(fields: group_866_867_868_fields, all_holdings:, holding_id:)
    end
  end
  all_holdings
end

def add_permanent_items_to_holdings(items_by_holding, field_852, holdings_helpers, all_holdings, holding)
  locations = holdings_helpers.select_permanent_location_876(items_by_holding, field_852)

  locations.each do |field_876|
    holding_key = holdings_helpers.holding_id(field_852)
    add_item_to_holding(field_852, field_876, holding_key, holdings_helpers, all_holdings, holding)
  end
end

def add_temporary_items_to_holdings(items_by_holding, field_852, holdings_helpers, all_holdings)
  locations = holdings_helpers.select_temporary_location_876(items_by_holding, field_852)

  locations.each do |field_876|
    next if holdings_helpers.includes_only_private_scsb_items?(field_852)

    if holdings_helpers.current_location_code(field_876) == 'RES_SHARE$IN_RS_REQ'
      holding = holdings_helpers.build_holding(field_852, permanent: true)
      holding_key = holdings_helpers.holding_id(field_852)
    else
      holding = holdings_helpers.build_holding(field_852, field_876, permanent: false)
      holding_key = holdings_helpers.current_location_code(field_876)
    end
    holding['temp_location_code'] = holdings_helpers.current_location_code(field_876)
    add_item_to_holding(field_852, field_876, holding_key, holdings_helpers, all_holdings, holding)
  end
end

def add_item_to_holding(field_852, field_876, holding_key, holdings_helpers, all_holdings, holding)
  item = holdings_helpers.build_item(field_852:, field_876:)
  if (holding_key.present? || !invalid_location?(holding['location_code'])) && all_holdings[holding_key].nil?
    all_holdings[holding_key] = remove_empty_call_number_fields(holding)
  end
  all_holdings = holdings_helpers.holding_items(value: holding_key, all_holdings:, item:)
end

def invalid_location?(code)
  Traject::TranslationMap.new('locations')[code].nil?
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
    elsif partner_lib == 'scsbhl'
      partner_display_string = 'H'
    end
    item_notes << "#{partner_display_string} - #{col_group}"
  end
  item_notes
end

def local_heading?(field)
  field.any? { |subfield| subfield.code == '2' && subfield.value == 'local' } &&
    field.any? { |subfield| subfield.code == '5' && subfield.value == 'NjP' }
end

def siku_heading?(field)
  any_thesaurus_match? field, %w[sk skbb]
end

def any_thesaurus_match?(field, thesauri)
  field.any? { |subfield| subfield.code == '2' && thesauri.include?(subfield.value) }
end

def valid_linked_fields(record, field_tag, accumulator)
  accumulator.concat LinkedFieldsExtractor.new(record, field_tag).mms_ids
end
