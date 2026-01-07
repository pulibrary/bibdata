class ActionNoteBuilder
  attr_reader :record, :marc_breaker

  def initialize(record:, marc_breaker:)
    @record = record
    @marc_breaker = marc_breaker || MarcBreaker.break(record)
  end

  def self.build(record:, marc_breaker:)
    new(record:, marc_breaker:).build
  end

  def build
    notes = []

    @record.fields('583').each do |field|
      public_note = field.indicator1 == '1'
      field_link = field['8']
      next unless public_note && (field_link.present? || pulfa_record? || scsb_record?)

      notes << { description: description(field), uri: uri(field) }
    end
    notes = [notes.to_json] if notes.present?
    notes.presence
  end

  private

    def description(field)
      description = ''
      description << materials_specified(field)
      description << action(field)
      description << action_interval(field)
      description << authorization_phrase(field)
      description << institution(field)
    end

    def uri(field)
      return '' if field['u'].blank?

      field['u'].strip
    end

    def action(field)
      return '' if field['a'].blank?

      field['a']&.upcase_first
    end

    def action_interval(field)
      return '' if field['d'].blank?

      " #{field['d']}"
    end

    def authorization_phrase(field)
      return '' if field['f'].blank?

      auth_array = authorization_array(field)
      auth_phrase = ''
      first_auth = auth_array.shift
      auth_phrase << " — #{first_auth}"
      auth_array.each do |auth|
        auth_phrase << " #{auth}"
      end
      auth_phrase
    end

    def authorization_array(field)
      field.subfields.select { |s_field| s_field.code == 'f' }.map(&:value)
    end

    def institution(field)
      return '' if field['5'].blank?

      " (#{field['5']})"
    end

    def materials_specified(field)
      return '' if field['3'].blank?

      "#{field['3']}: "
    end

    def pulfa_record?
      @pulfa_record ||= @record.fields('035').any? { |f| f['a']&.downcase =~ /pulfa/ }
    end

    def scsb_record?
      @scsb_record ||= BibdataRs::Marc.is_scsb?(marc_breaker)
    end
end
