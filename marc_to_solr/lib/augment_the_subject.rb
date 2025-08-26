# frozen_string_literal: true

require 'set'

##
# The creation and management of metadata are not neutral activities.
class AugmentTheSubject
  LCSH_TERMS_CSV_FILE = File.join(File.dirname(__FILE__), 'augment_the_subject', 'indigenous_studies.csv')
  # Can be re-created using `bundle exec rake augment:recreate_fixtures`
  LCSH_STANDALONE_A_FILE = File.join(File.dirname(__FILE__), 'augment_the_subject', 'standalone_subfield_a.json')
  # Must be created by hand from file provided by metadata librarians
  LCSH_STANDALONE_X_FILE = File.join(File.dirname(__FILE__), 'augment_the_subject', 'standalone_subfield_x.json')
  # Can be re-created using `bundle exec rake augment:recreate_fixtures`
  LCSH_REQUIRED_SUBFIELDS = File.join(File.dirname(__FILE__), 'augment_the_subject', 'indigenous_studies_required.json')

  ##
  # Ensure the needed config files exist
  def initialize
    raise "Cannot find lcsh csv file at #{LCSH_TERMS_CSV_FILE}" unless File.exist?(LCSH_TERMS_CSV_FILE)
    unless File.exist?(LCSH_STANDALONE_A_FILE)
      raise "Cannot find lcsh standalone subfield a file at #{LCSH_STANDALONE_A_FILE}"
    end
    unless File.exist?(LCSH_STANDALONE_X_FILE)
      raise "Cannot find lcsh standalone subfield x file at #{LCSH_STANDALONE_X_FILE}"
    end
    unless File.exist?(LCSH_REQUIRED_SUBFIELDS)
      raise "Cannot find lcsh required subfields file at #{LCSH_REQUIRED_SUBFIELDS}"
    end
  end

  def standalone_subfield_a_terms
    @standalone_subfield_a_terms ||= begin
      parsed_json = JSON.parse(File.read(LCSH_STANDALONE_A_FILE), { symbolize_names: true })
      parsed_json[:standalone_subfield_a].map do |term|
        normalize(term)
      end.to_set
    end
  end

  def standalone_subfield_x_terms
    @standalone_subfield_x_terms ||= begin
      parsed_json = JSON.parse(File.read(LCSH_STANDALONE_X_FILE), { symbolize_names: true })
      parsed_json[:standalone_subfield_x].map do |term|
        normalize(term)
      end
    end
  end

  def indigenous_studies_required
    @indigenous_studies_required ||= begin
      parsed_json = JSON.parse(File.read(LCSH_REQUIRED_SUBFIELDS), { symbolize_names: false })
      # Turns all the sub-arrays into sets for set comparison later
      parsed_json.transform_values! do |value|
        value.map do |val|
          val.map { |term| normalize(term) }.to_set
        end
      end
      # Normalizes and symbolizes key for fast and consistent retrieval
      parsed_json.transform_keys! do |key|
        normalize(key).to_sym
      end
    end
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
    terms << 'Indigenous Studies' if indigenous_studies?(terms)
    terms
  end

  ##
  # Given an array of terms, check whether this set of terms should have an
  # additional subject heading of "Indigenous Studies" added
  # @param [<String>] terms
  # @return [Boolean]
  def indigenous_studies?(terms)
    terms.each do |term|
      next if term.blank?

      return true if subfield_a_match?(term)
      return true if subfield_x_match?(term)
      return true if subfield_a_with_required_subfields_match?(term)
    end
    false
  end

  ##
  # For some subject terms, only the first part needs to match.
  # E.g., "Quinnipiac Indians-History", "Quinnipiac Indians-Culture" should both
  # be assigned an Indigenous Studies term even though that entire term doesn't
  # appear in our terms list.
  def subfield_a_match?(term)
    subfield_a = normalize(term.split(SEPARATOR).first).gsub(/\.$/, '')
    standalone_subfield_a_terms.include?(subfield_a)
  end

  ##
  # For some subfield terms, only a single subfield needs to match.
  # E.g., any subject term that includes "Indian authors" should be assigned Indigenous Studies
  def subfield_x_match?(term)
    subfields = term.split(SEPARATOR)
    subfields = subfields.map { |subfield| normalize(subfield) }
    !(standalone_subfield_x_terms & subfields).empty?
  end

  ##
  # Some subject terms require a combination of terms in order to be assigned Indigenous Studies.
  # For example, "Alaska-Antiquities" should be a match, but "Alaska" by itself should not,
  # nor should "Antiquities" by itself.
  def subfield_a_with_required_subfields_match?(term)
    subfields = term.split(SEPARATOR)
    subfields = subfields.map { |subfield| normalize(subfield) }
    subfield_a = subfields.shift.to_sym

    required_subfields = indigenous_studies_required[subfield_a]
    return false unless required_subfields

    required_subfields.map do |req_terms|
      return true if req_terms.subset?(subfields.to_set)
    end
    false
  end

  # In order to re-write the fixture file based on a new CSV, run the rake task
  # `bundle exec rake augment:recreate_fixtures`
  def self.parse_standalone_a
    subfield_a_aggregator = Set.new
    CSV.foreach(LCSH_TERMS_CSV_FILE, headers: true) do |row|
      requires_subfield = row['With subdivisions ǂx etc.'] == 'y'
      unless requires_subfield
        lcsh_term = row['Term in MARC']
        subfield_a = lcsh_term.chomp.split('ǂ').first.strip
        subfield_a_aggregator << subfield_a
      end
    end
    output = {}
    output[:standalone_subfield_a] = subfield_a_aggregator.sort
    output
  end

  # In order to re-write the fixture file based on a new CSV, run the rake task
  # `bundle exec rake augment:recreate_fixtures`
  def self.parse_required_subfields
    output = {}
    CSV.foreach(LCSH_TERMS_CSV_FILE, headers: true) do |row|
      if row['With subdivisions ǂx etc.'] == 'y'
        term = row['Term in MARC']
        term_list = term.chomp.split(/ ǂ. /)
        subfield_a = term_list.shift
        if output[subfield_a]
          output[subfield_a] << term_list
        else
          output[subfield_a] = [term_list]
        end
      end
    end
    output.to_json
  end
end
