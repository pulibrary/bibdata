# frozen_string_literal: true

require 'set'

##
# The creation and management of metadata are not neutral activities.
class AugmentTheSubject
  LCSH_TERMS_FILE = File.join(File.dirname(__FILE__), 'augment_the_subject', 'indigenous_studies.txt')

  ##
  # Ensure the needed config files exist
  def initialize
    raise "Cannot find lcsh terms file at #{LCSH_TERMS_FILE}" unless File.exist?(LCSH_TERMS_FILE)
  end

  def indigenous_studies_terms
    @indigenous_studies_terms || load_indigenous_studies_terms
  end

  def load_indigenous_studies_terms
    @indigenous_studies_terms = Set.new
    File.foreach(LCSH_TERMS_FILE) do |lcsh_term|
      @indigenous_studies_terms << normalize(lcsh_term)
    end
    @indigenous_studies_terms
  end

  ##
  # Normalize lcsh terms so they can match at index time.
  # 1. downcase
  # 2. replace ǂ terms with SEPARATOR
  def normalize(lcsh_term)
    lcsh_term.chomp.downcase.gsub(/ ǂ. /, SEPARATOR)
  end

  ##
  # Given an array of terms, add "Indigenous Studies" if any of the terms match
  # @param [<String>] terms
  # @return [<String>]
  def add_indigenous_studies(terms)
    terms << "Indigenous Studies" if indigenous_studies?(terms)
    terms
  end

  ##
  # Given an array of terms, check whether this set of terms should have an
  # additional subject heading of "Indigenous Studies" added
  # @param [<String>] terms
  # @return [Boolean]
  def indigenous_studies?(target_terms)
    target_terms.each do |term|
      term = normalize(term)
      matches = full_subject_term_match?(term)
      return true if matches
    end
    false
  end

  ##
  # For some subject terms, we need to match on all subfields
  # E.g., Russia (Federation)-Civilization-Indian influences
  # However, we should not match on only partial matches
  # E.g., Alaska should not match, but Alaska-Antiquities should match
  def full_subject_term_match?(term)
    matches = indigenous_studies_terms.map do |lc_term|
      %r{^#{lc_term}}.match?(term)
    end
    return true if matches.include?(true)
  end
end
