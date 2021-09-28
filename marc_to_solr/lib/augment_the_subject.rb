# frozen_string_literal: true

require 'set'

##
# The creation and management of metadata are not neutral activities.
class AugmentTheSubject
  ##
  # Ensure the needed config files exist
  def initialize
    @lcsh_terms_file = File.join(File.dirname(__FILE__), 'augment_the_subject', 'indigenous_studies.txt')
    raise "Cannot find indigenous_studies lcsh terms file" unless File.exist?(@lcsh_terms_file)
  end

  def indigenous_studies_terms
    @indigenous_studies_terms || load_indigenous_studies_terms
  end

  def load_indigenous_studies_terms
    @indigenous_studies_terms = Set.new
    File.foreach(@lcsh_terms_file) do |lcsh_term|
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
  def indigenous_studies?(terms)
    terms.each do |term|
      return true if indigenous_studies_terms.include? term.downcase.gsub(/[^\w\s#{SEPARATOR}]/, '')
    end
    false
  end
end
