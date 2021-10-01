# frozen_string_literal: true

##
# The creation and management of metadata are not neutral activities.
class ChangeTheSubject
  def initialize
    @terms_mapping = {
      "Illegal Aliens": {
        replacement: "Undocumented Immigrants",
        rationale: "The term immigrant or undocumented/unauthorized immigrants are the terms LoC proposed as replacements for illegal aliens and other uses of the world alien in LCSH."
      }
    }
  end

  ##
  # Given an array of subject terms, replace the ones that need replacing
  # @param [<String>] subject_terms
  # @return [<String>]
  def fix(subject_terms)
    subject_terms.map { |term| check_for_replacement(term) }
  end

  ##
  # Given a term, check whether there is a suggested replacement.
  # Remove punctuation and downcase the term
  # Compare with the downcase key from @terms_mapping
  # If the strings match replace the suggested term, otherwise return the term unaltered.
  # @param [String] term
  # @return [String]
  def check_for_replacement(term)
    term_downcase = remove_punctuation(term).downcase
    terms_mapping_key = @terms_mapping.map { |k, _v| k.downcase }.first
    replacement = terms_mapping_key && terms_mapping_key == term_downcase.to_sym ? @terms_mapping.values.first[:replacement] : term
  end

  # Remove punctuation from subfields in order to compare with the terms_mapping key.
  # example 650$a: "illegal aliens."
  def remove_punctuation(value)
    value.gsub(/[^A-Za-z0-9\s]/i, '')
  end
end
