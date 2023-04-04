# A class to pull out language information from
# a MARC record
class LanguageExtractor
  def initialize(language_service, marc_record)
    @marc_record = marc_record
    @language_service = language_service
  end

  def specific_codes
    codes = []
    codes << fixed_field_code if fixed_field_code

    if iso_041_fields.any?
      codes.concat(iso_041_codes)
    elsif all_041_fields.any?
      codes.concat(all_041_codes)
    end
    codes.uniq.reject { |general_code| includes_more_specific_version?(codes, general_code) }
  end

  def specific_names
    specific_codes.map { |code| @language_service.code_to_name(code) }
                  .compact
  end

  def iso639_language_names
    iso_041_codes.map { |code| @language_service.code_to_name(code) }
                 .compact
  end

  private

    def includes_more_specific_version?(codes, code_to_check)
      codes.any? { |individual| @language_service.macrolanguage_codes(individual).include? code_to_check }
    end

    def iso_041_fields
      all_041_fields.select { |field| field['2'] == 'iso639-3' }
    end

    def all_041_fields
      @marc_record.fields('041')
    end

    def fixed_field_code
      value = @marc_record['008']&.value
      fixed_field_code = value ? value[35, 3] : nil
    end

    def iso_041_codes
      return [] unless iso_041_fields.any?
      extract_from_multiple_041s(iso_041_fields)
    end

    def all_041_codes
      return [] unless all_041_fields.any?
      extract_from_multiple_041s(all_041_fields)
    end

    def extract_from_multiple_041s(fields)
      fields.map do |field|
        field.subfields.select { |sf| %(a d).include? sf.code }
             .map(&:value)
      end.flatten
    end
end
