# frozen_string_literal: true
require 'languages'

class LanguageService
  def loc_to_iana(loc)
    if Languages[loc]&.alpha2.blank? || ["zxx", "mul", "sgn", "und", "|||"].include?(loc)
      "en"
    else
      Languages[loc].alpha2.to_s
    end
  end

  def valid_language_code?(code)
    return false if code.blank?
    Languages[code].present? || iso_639_5_include?(code)
  end

  def code_to_name(code)
    Languages[code]&.name || iso_639_5_name(code)
  end

  def macrolanguage_codes(individual_language_code)
    individual = Languages[individual_language_code]
    if individual.respond_to? :macrolanguage
      [individual&.macrolanguage&.alpha3_bibliographic.to_s, individual&.macrolanguage&.iso639_3.to_s].uniq
    else
      []
    end
  end

  private

    def iso639_5_collective_languages
      @iso639_5_collective_languages ||= CSV.read(Rails.root.join('config', 'iso639-5.tsv'), headers: true, col_sep: "\t")
    end

    def iso_639_5_include?(code)
      iso639_5_collective_languages['code'].include?(code)
    end

    def iso_639_5_name(code)
      return unless iso_639_5_include?(code)
      iso639_5_collective_languages.find { |row| row['code'] == code }['Label (English)']
    end
end
