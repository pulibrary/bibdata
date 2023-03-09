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
    Languages[code].present? || iso639_5_collective_languages['code'].include?(code)
  end

  private

    def iso639_5_collective_languages
      @iso639_5_collective_languages ||= CSV.read(Rails.root.join('config', 'iso639-5.tsv'), headers: true, col_sep: "\t")
    end
end
