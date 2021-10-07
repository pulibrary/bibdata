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
    return [] if subject_terms.nil? || subject_terms.blank?
    # byebug if subject_terms.first.match(/Illegal alien/)
    subject_terms.map { |term| check_for_replacement(term) }
  end

  ##
  # Given a term, check whether there is a suggested replacement. If there is, return
  # it. If there is not, return the term unaltered.
  # @param [String] term
  # @return [String]
  def self.check_for_replacement(term)
    subterms = term.split(SEPARATOR)
    # byebug if term.match(/Illegal alien/)
    subfield_a = subterms.first
    subterms.delete(subfield_a)
    replacement = terms_mapping[subfield_a.to_sym]
    return term unless replacement
    subterms.prepend(replacement[:replacement])
    subterms.join(SEPARATOR)
  end
end
