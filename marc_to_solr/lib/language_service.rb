# frozen_string_literal: true

require 'languages'
require_relative './indigenous_languages'

class LanguageService
  include IndigenousLanguages
  def loc_to_iana(loc)
    if can_be_represented_as_iana? loc
      Languages[loc].alpha2.to_s
    else
      'en'
    end
  end

  def loc_to_mult_iana(loc)
    return nil unless valid_language_code?(loc)

    two_char_version = Languages[loc]&.alpha2
    two_char_version ? two_char_version.to_s : loc
  end

  def can_be_represented_as_iana?(loc)
    valid_language_code?(loc) && Languages[loc]&.alpha2.present? && !['zxx', 'mul', 'sgn', 'und', '|||'].include?(loc)
  end

  def valid_language_code?(code)
    return false if code.blank?

    Languages[code].present? || iso_639_5_include?(code)
  end

  def code_to_name(code)
    BibdataRs::Languages.code_to_name(code) || iso_639_5_name(code)
  end

  def macrolanguage_codes(individual_language_code)
    individual = Languages[individual_language_code]
    if individual.respond_to? :macrolanguage
      [individual&.macrolanguage&.alpha3_bibliographic.to_s, individual&.macrolanguage&.iso639_3.to_s].uniq
    else
      []
    end
  end

  def specific_names(record)
    specific_codes(record).map { |code| code_to_name(code) }
                          .compact
  end

  def specific_codes(record)
    extractor = LanguageExtractor.new(record)
    codes = []
    codes << extractor.fixed_field_code if extractor.fixed_field_code

    if extractor.iso_041_fields.any?
      codes.concat(extractor.iso_041_codes)
    elsif extractor.all_041_fields.any?
      codes.concat(extractor.all_041_codes)
    end
    codes.uniq.reject { |general_code| includes_more_specific_version?(codes, general_code) }
  end

  def iso639_language_names(record)
    LanguageExtractor.new(record).iso_041_codes.map { |code| code_to_name(code) }
                     .compact
  end

  def includes_more_specific_version?(codes, code_to_check)
    codes.any? { |individual| macrolanguage_codes(individual).include? code_to_check }
  end

  private

    def iso639_5_collective_languages
      @iso639_5_collective_languages ||= CSV.read(File.join(File.dirname(__FILE__), 'iso639-5.tsv'), headers: true, col_sep: "\t")
    end

    def iso_639_5_include?(code)
      iso639_5_collective_languages['code'].include?(code)
    end

    def iso_639_5_name(code)
      return unless iso_639_5_include?(code)

      iso639_5_collective_languages.find { |row| row['code'] == code }['Label (English)']
    end
end
