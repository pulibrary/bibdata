require 'traject/macros/marc21_semantics'

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
      d = self['008'].value[7,4].gsub 'u', '0'
      d if d =~ /^[0-9]{4}$/
    end

  end
end