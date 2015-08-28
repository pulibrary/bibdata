require 'library_stdnums'

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

def remove_parens_035 standard_no
  standard_no.gsub(/^\(.*?\)/,'')
end