# frozen_string_literal: true

class EmbargoDateExtractor
  def initialize(record)
    @record = record
  end

  def dates
    @dates ||= extract_dates
  end

  private

    def extract_dates
      restriction_notes = @record.select do |field|
        field.tag == '506' &&
          field.any? { |subfield| subfield.code == '5' && subfield.value == 'NjP' } &&
          field.any? { |subfield| subfield.code == 'g' }
      end
      restriction_notes.map { |field| parse_date(field['g']) }.compact
    end

    def parse_date(string)
      year = string[0..3].to_i
      month = string[4..5].to_i
      day = string[6..7].to_i
      Date.new(year, month, day) if Date.valid_date?(year, month, day)
    end
end
