# frozen_string_literal: true

# This class is responsible for extracting and validating
# Alma MMS IDs from the 773 and 774 MARC fields
class LinkedFieldsExtractor
  def initialize(record, field_tag)
    @record = record
    @field_tag = field_tag
  end

  def mms_ids
    valid_fields.map { |field| field['w'].delete_prefix('(NjP)') }
  end

  private

    attr_accessor :record, :field_tag

    def valid_fields
      @valid_fields ||= record.fields(field_tag).select do |field|
        value = field['w']
        # The regular expression /99[0-9]+6421/ ensures that an mms id is present in a $w
        value =~ /99[0-9]+6421/ && value.start_with?(/(\(NjP\))?99/) && value.end_with?('06421')
      end
    end
end
