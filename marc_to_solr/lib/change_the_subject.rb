# frozen_string_literal: true

##
# The creation and management of metadata are not neutral activities.
class ChangeTheSubject
  def self.terms_mapping
    {
      "Illegal aliens": {
        replacement: "Undocumented immigrants",
        rationale: "The term immigrant or undocumented/unauthorized immigrants are the terms LoC proposed as replacements for illegal aliens and other uses of the world alien in LCSH."
      }
    }
  end

  ##
  # Given an array of subject terms, replace the ones that need replacing
  # @param [<String>] subject_terms
  # @return [<String>]
  def self.fix(subject_terms)
    return [] if subject_terms.nil?
    subject_terms = subject_terms.compact.reject(&:empty?)
    return [] if subject_terms.blank?
    subject_terms.map { |term| check_for_replacement(term) }
  end

  ##
  # Given an array of subject terms, remove the ones that need to be removed
  # @param [<String>] subject_terms
  # @return [<String>]
  def self.remove(subject_terms)
    return [] if subject_terms.nil?
    subject_terms = subject_terms.compact.reject(&:empty?)
    return [] if subject_terms.blank?
    subject_terms.map { |term| check_to_remove(term) }
  end

  ##
  # Given a term, check whether there is a suggested replacement. If there is, return
  # it. If there is not, return the term unaltered.
  # @param [String] term
  # @return [String]
  def self.check_for_replacement(term)
    subterms = term.split(SEPARATOR)
    subfield_a = subterms.first
    replacement = terms_mapping[subfield_a.to_sym]
    return term unless replacement
    subterms.delete(subfield_a)
    subterms.prepend(replacement[:replacement])
    subterms.join(SEPARATOR)
  end

  ##
  # Given a term, check whether there is a suggested replacement. If there is, remove it.
  # If there is not, return the term unaltered.
  # @param [String] term
  # @return [String]
  def self.check_to_remove(term)
    subterms = term.split(SEPARATOR)
    subfield_a = subterms.first
    replacement = terms_mapping[subfield_a.to_sym]
    return term unless replacement
    return if replacement
  end
end
