# frozen_string_literal: true

require 'ffi-icu'

module CJKFactory
  def self.traditional_to_simplified(string)
    transliterate('Traditional-Simplified', string)
  end

  def self.katakana_to_hiragana(string)
    transliterate('Katakana-Hiragana', string)
  end

  def self.contains_chinese?(string)
    /\p{Han}/.match string
  end

  def self.contains_katakana?(string)
    /\p{Katakana}/.match string
  end

  def self.transliterate(icu_id, string)
    ICU::Transliteration.transliterate(icu_id, string)
  end
end
