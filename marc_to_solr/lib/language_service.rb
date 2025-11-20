# frozen_string_literal: true

require 'languages'
require_relative './indigenous_languages'

class LanguageService
  include IndigenousLanguages

  def loc_to_mult_iana(loc)
    return nil unless valid_language_code?(loc)

    BibdataRs::Languages.two_letter_code(loc.to_s) || loc
  end

  def valid_language_code?(code)
    return false if code.blank?

    # Rust strings need to be UTF-8 encoded, so let's confirm
    # that the encoding is valid before sending it to Rust
    code_as_string = code.to_s
    return false unless code_as_string.valid_encoding?

    BibdataRs::Languages.valid_language_code?(code_as_string)
  end

  def code_to_name(code)
    BibdataRs::Languages.code_to_name(code) || iso_639_5_name(code)
  end

  def macrolanguage_codes(individual_language_code)
    BibdataRs::Languages.macrolanguage_codes(individual_language_code)
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
