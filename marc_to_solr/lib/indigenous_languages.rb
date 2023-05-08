# frozen_string_literal: true

# Identify materials in indigenous languages
# from the Western Hemisphere
module IndigenousLanguages
  def in_an_indigenous_language?(record)
    language_extractor = LanguageExtractor.new(record)
    language_extractor.all_language_codes.any? { |code| language_codes.include? code } ||
      language_extractor.possible_language_subject_headings.any? { |heading| subject_headings.include? heading }
  end

  def subject_headings
    @subject_headings ||= fetch_subject_headings_from_file
  end

  def language_codes
    @language_codes ||= fetch_language_codes_from_file
  end

  private

    def fetch_subject_headings_from_file
      column_name = 'LCSH for indigenous languages'
      csv = CSV.read(File.join(File.dirname(__FILE__), 'augment_the_facet', 'indigenous_languages_western_hemisphere_lcsh.csv'), headers: true)
      raise "Invalid CSV format, must have a column named \"#{column_name}\" containing LCSH" unless csv.headers.include? column_name
      csv[column_name]
    end

    def fetch_language_codes_from_file
      csv = CSV.read(File.join(File.dirname(__FILE__), 'augment_the_facet', 'indigenous_languages_western_hemisphere_codes.csv'), headers: true)
      column_contents = csv[csv.headers.first]
      column_contents.select { |entry| entry&.length == 3 }
                     .uniq
    end
end
