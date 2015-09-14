# encoding: UTF-8
require 'library_stdnums'
require 'uri'

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
        d = self['008'].value[7,4] 
        d = d.gsub 'u', '0' unless d == 'uuuu'
        d = d.gsub ' ', '0' unless d == '    '  
        d if d =~ /^[0-9]{4}$/
      end
    end

    def end_date_from_008
      if self['008']
        d = self['008'].value[11,4] 
        d = d.gsub 'u', '0' unless d == 'uuuu'
        d = d.gsub ' ', '0' unless d == '    '  
        d if d =~ /^[0-9]{4}$/
      end
    end

    def date_display
      date = nil
      if self['260']
        if self['260']['c']
          date = self['260']['c']
        end
      end
      date ||= self.date_from_008
    end

  end
end

FALLBACK_STANDARD_NO = "Other standard number"
def map_024_indicators_to_labels i
  case i
  when '0' then "International Standard Recording Code"
  when '1' then "Universal Product Code"
  when '2' then "International Standard Music Number"
  when '3' then "International Article Number"
  when '4' then "Serial Item and Contribution Identifier"
  when '7' then '$2'
  else FALLBACK_STANDARD_NO
  end
end

def subfield_specified_hash_key subfield_value, fallback
  key = subfield_value.capitalize.gsub(/[[:punct:]]?$/,'')
  key == '' ? fallback : key
end

def standard_no_hash record
  standard_no = {}
  Traject::MarcExtractor.cached('024').collect_matching_lines(record) do |field, spec, extractor|
    standard_label = map_024_indicators_to_labels(field.indicator1)
    standard_number = ''
    field.subfields.each do |s_field|
      standard_number = s_field.value if s_field.code == 'a'
      standard_label = subfield_specified_hash_key(s_field.value, FALLBACK_STANDARD_NO) if s_field.code == '2' and standard_label == '$2'
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
def other_versions record
  linked_nums = []
  Traject::MarcExtractor.cached('020az:022alyz:035a:776wxz:787w').collect_matching_lines(record) do |field, spec, extractor|
    field.subfields.each do |s_field|
      linked_nums << StdNum::ISBN.normalize(s_field.value) if (field.tag == "020") or (field.tag == "776" and s_field.code == 'z')
      linked_nums << StdNum::ISSN.normalize(s_field.value) if (field.tag == "022") or (field.tag == "776" and s_field.code == 'x')
      if (field.tag == "035") or (field.tag == "776" and s_field.code == 'w') or (field.tag == "787" and s_field.code == 'w')
        linked_nums << oclc_normalize(s_field.value, prefix: true) if s_field.value.start_with?('(OCoLC)')
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
        remove << " #{s_field.value}" if after_t and spec.includes_subfield_code?(s_field.code)
        after_t = true if s_field.code == 't'
      end
      name = name.chomp(remove)
      names << Traject::Macros::Marc21.trim_punctuation(name)
    end
  end
  names.uniq
end

SEPARATOR = '—'

# for the hierarchical subject display and facet
# split with em dash along v,x,y,z
def process_subject_facet record
  subjects = []
  Traject::MarcExtractor.cached('600|*0|abcdfklmnopqrtvxyz:600|*7|abcdfklmnopqrtvxyz:610|*0|abfklmnoprstvxyz:610|*7|abfklmnoprstvxyz:611|*0|abcdefgklnpqstvxyz:611|*7|abcdefgklnpqstvxyz:630|*0|adfgklmnoprstvxyz:630|*7|adfgklmnoprstvxyz:650|*0|abcvxyz:650|*7|abcvxyz:651|*0|avxyz:651|*7|avxyz').collect_matching_lines(record) do |field, spec, extractor|
    subject = extractor.collect_subfields(field, spec).first
    unless subject.nil?
      field.subfields.each do |s_field|
        if (s_field.code == 'v' || s_field.code == 'x' || s_field.code == 'y' || s_field.code == 'z')
          subject = subject.gsub(" #{s_field.value}", "#{SEPARATOR}#{s_field.value}")
        end
      end
      subjects << Traject::Macros::Marc21.trim_punctuation(subject)
    end
  end
  subjects
end

# for the split subject facet
# split with em dash along x,z
def process_subject_topic_facet record
  subjects = []
  Traject::MarcExtractor.cached('600|*0|abcdfklmnopqrtxz:600|*7|abcdfklmnopqrtxz:610|*0|abfklmnoprstxz:610|*7|abfklmnoprstxz:611|*0|abcdefgklnpqstxz:611|*7|abcdefgklnpqstxz:630|*0|adfgklmnoprstxz:630|*7|adfgklmnoprstxz:650|*0|abcxz:650|*7|abcxz:651|*0|axz:651|*7|axz').collect_matching_lines(record) do |field, spec, extractor|
    subject = extractor.collect_subfields(field, spec).first
    unless subject.nil?
      field.subfields.each do |s_field|
        if (s_field.code == 'x' || s_field.code == 'z')
          subject = subject.gsub(" #{s_field.value}", "#{SEPARATOR}#{s_field.value}")
        end
      end
      subject = subject.split(SEPARATOR)
      subjects << subject.map { |s| Traject::Macros::Marc21.trim_punctuation(s) }
    end
  end
  subjects.flatten
end

def oclc_normalize oclc, opts = {prefix: false}
  oclc_num = oclc.gsub(/\D/, '').to_i.to_s
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

# returns hash of links ($u) (key),
# anchor text ($y, $3, hostname), and additional labels ($z) (array value)
def electronic_access_links record
  links = {}
  Traject::MarcExtractor.cached('856').collect_matching_lines(record) do |field, spec, extractor|
    anchor_text = false
    z_label = false
    url = false
    field.subfields.each do |s_field|
      url = s_field.value if s_field.code == 'u'
      z_label = s_field.value if s_field.code == 'z'
      if s_field.code == 'y' || s_field.code == '3'
        if anchor_text
          anchor_text << ": #{s_field.value}"
        else
          anchor_text = s_field.value
        end
      end
    end
    if url and (URI.parse(url) rescue nil)
      anchor_text = URI.parse(url).host unless anchor_text
      links[url] = [anchor_text] # anchor text is first element
      links[url] << z_label if z_label # optional 2nd element if z
    end
  end
  links
end

def remove_parens_035 standard_no
  standard_no.gsub(/^\(.*?\)/,'')
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

# 600/610/650/651 $v, $x filtered
# 655 $a, $v, $x filtered
def process_genre_facet record
  genres = []
  Traject::MarcExtractor.cached('600|*0|x:600|*7|x:610|*0|x:610|*7|x:611|*0|x:611|*7|x:630|*0|x:630|*7|x:650|*0|x:650|*7|x:651|*0|x:651|*7|x:655|*0|x:655|*7|x').collect_matching_lines(record) do |field, spec, extractor|
    genre = extractor.collect_subfields(field, spec).first
    unless genre.nil?
      genre = Traject::Macros::Marc21.trim_punctuation(genre)
      genres << genre if GENRES.include?(genre) || GENRE_STARTS_WITH.any? { |g| genre[g] }
    end
  end
  Traject::MarcExtractor.cached('600|*0|v:600|*7|v:610|*0|v:610|*7|v:611|*0|v:611|*7|v:630|*0|v:630|*7|v:650|*0|v:650|*7|v:651|*0|v:651|*7|v:655|*0|a:655|*7|a:655|*0|v:655|*7|v').collect_matching_lines(record) do |field, spec, extractor|
    genre = extractor.collect_subfields(field, spec).first
    unless genre.nil?
      genre = Traject::Macros::Marc21.trim_punctuation(genre)
      genres << genre
    end
  end
  genres.uniq
end
