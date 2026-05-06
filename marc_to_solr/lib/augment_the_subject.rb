# frozen_string_literal: true

##
# This class is responsible for preparing data from a CSV file into hashes that can be
# used to determine whether or not subjects are relevant to the field of Indigenous Studies
class AugmentTheSubject
  LCSH_TERMS_CSV_FILE = File.join(File.dirname(__FILE__), 'augment_the_subject', 'indigenous_studies.csv')

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
