# A class to pull out language information from
# a MARC record
class LanguageExtractor
  def initialize(marc_record)
    @marc_record = marc_record
  end

  def all_language_codes
    all_041_codes.append(fixed_field_code).compact.uniq
  end

  def possible_language_subject_headings
    @marc_record.fields('650')
                .select { |field| field['v'] == 'Texts' }
                .map { |field| field['a'] }
  end

  def fixed_field_code
    value = @marc_record['008']&.value
    fixed_field_code = value ? value[35, 3] : nil
  end

  def iso_041_fields
    all_041_fields.select { |field| field['2'] == 'iso639-3' }
  end

  def all_041_fields
    @marc_record.fields('041')
  end

  def iso_041_codes
    return [] unless iso_041_fields.any?

    extract_from_multiple_041s(iso_041_fields)
  end

  def all_041_codes
    return [] unless all_041_fields.any?

    extract_from_multiple_041s(all_041_fields)
  end

  private

    def extract_from_multiple_041s(fields)
      fields.map do |field|
        field.subfields.select { |sf| %(a d).include? sf.code }
             .map(&:value)
      end.flatten
    end
end
