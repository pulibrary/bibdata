# frozen_string_literal: true

require 'set'

##
# The creation and management of metadata are not neutral activities.
class AugmentTheSubject
  LCSH_TERMS_FILE = File.join(File.dirname(__FILE__), 'augment_the_subject', 'indigenous_studies.txt')
  LCSH_SUBFIELDS_FILE = File.join(File.dirname(__FILE__), 'augment_the_subject', 'indigenous_studies_subfields.json')

  ##
  # Ensure the needed config files exist
  def initialize
    raise "Cannot find lcsh terms file at #{LCSH_TERMS_FILE}" unless File.exist?(LCSH_TERMS_FILE)
    raise "Cannot find lcsh subfields file at #{LCSH_SUBFIELDS_FILE}" unless File.exist?(LCSH_SUBFIELDS_FILE)
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

  def indigenous_studies_subfields
    @indigenous_studies_subfields || load_indigenous_studies_subfields
  end

  def load_indigenous_studies_subfields
    @indigenous_studies_subfields = JSON.parse(File.read(LCSH_SUBFIELDS_FILE))
    @indigenous_studies_subfields
  end

  ##
  # Normalize lcsh terms so they can match at index time.
  # 1. downcase
  # 2. replace ǂ terms with SEPARATOR
  def normalize(lcsh_term)
    lcsh_term.chomp.downcase.gsub(/ ǂ. /, SEPARATOR)
  end

  ##
  # Given an array of terms, add "Indigenous studies" if any of the terms match
  # @param [<String>] terms
  # @return [<String>]
  def add_indigenous_studies(terms)
    terms << "Indigenous studies" if indigenous_studies?(terms)
    terms
  end

  ##
  # Given an array of terms, check whether this set of terms should have an
  # additional subject heading of "Indigenous studies" added
  # @param [<String>] terms
  # @return [Boolean]
  def indigenous_studies?(terms)
    terms.each do |term|
      return true if subfield_a_match?(term)
      return true if full_subject_term_match?(term)
    end
    false
  end

  ##
  # For some subject terms, only the first part needs to match.
  # E.g., "Quinnipiac Indians-History", "Quinnipiac Indians-Culture" should both
  # be assigned an Indigenous studies term even though that entire term doesn't
  # appear in our terms list.
  def subfield_a_match?(term)
    subfield_a = term.split(SEPARATOR).first
    indigenous_studies_subfields["a"].include?(subfield_a)
  end

  ##
  # For some subject terms, we need to match on all subfields
  # E.g., Russia (Federation)-Civilization-Indian influences
  def full_subject_term_match?(term)
    indigenous_studies_terms.include? term.downcase.gsub(/[^\w\s#{SEPARATOR}]/, '')
  end

  ##
  # DANGER ZONE
  # This will re-parse the indigenous_studies.txt file into a json file that
  # has split apart the marc subfields. A person will then need to go in and
  # manually edit the json config file to remove irrelevant subjects.
  def self.parse_subjects
    subfield_a = Set.new
    subfield_x = Set.new
    subfield_y = Set.new
    subfield_z = Set.new
    File.foreach(LCSH_TERMS_FILE) do |lcsh_term|
      subfield_a << lcsh_term.chomp.split('ǂ').first.strip
      subfield_x << lcsh_term.chomp.split("ǂx").last.strip.split("ǂ").first.strip if lcsh_term =~ /ǂx/
      subfield_y << lcsh_term.chomp.split("ǂy").last.strip.split("ǂ").first.strip if lcsh_term =~ /ǂy/
      subfield_z << lcsh_term.chomp.split("ǂz").last.strip.split("ǂ").first.strip if lcsh_term =~ /ǂz/
    end
    output = {}
    output[:a] = subfield_a.sort
    output[:x] = subfield_x.sort
    output[:y] = subfield_y.sort
    output[:z] = subfield_z.sort
    ## Uncomment this line to re-write the subfields file. Remember that you will then need to edit it by hand.
    # File.open(lcsh_subfields_file, "w") { |f| f.write output.to_json }
    output
  end
end
