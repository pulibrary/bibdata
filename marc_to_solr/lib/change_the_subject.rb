# frozen_string_literal: true

##
# The creation and management of metadata are not neutral activities.
class ChangeTheSubject
  def self.terms_mapping
    {
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
  def self.fix(subject_terms)
    subject_terms.map { |term| check_for_replacement(term) }
  end

  ##
  # Given a term, check whether there is a suggested replacement. If there is, return
  # it. If there is not, return the term unaltered.
  # @param [String] term
  # @return [String]
  def self.check_for_replacement(term)
    replacement = terms_mapping[term.to_sym]
    return replacement[:replacement] if replacement
    term
  end
end
