# This class is responsible for converting MARC records into the
# MarcBreaker format (see https://www.loc.gov/marc/makrbrkr.html)
#
# The use case for this format is to be able to pass Marc records
# to the Rust code in a format understood by the MarcTK crate, without
# using ruby-marc's slow MarcXML serialization routines
class MarcBreaker
  def initialize(original)
    @original = original
  end

  def self.break(original)
    breaker = new(original)
    breaker.as_breaker
  end

  def as_breaker
    fields = original.fields
                     .select { |f| valid_tag? f.tag }
                     .map do |f|
      case f
      when MARC::DataField
        datafield_to_breaker(f)
      when MARC::ControlField
        control_field_to_breaker(f)
      end
    end
    fields = [leader_to_breaker(original.leader).to_s] + fields if original.leader
    fields.join("\n")
  end

  private

    MARC_BREAKER_SF_DELIMITER = '$'.freeze
    MARC_BREAKER_SF_DELIMITER_ESCAPE = '{dollar}'.freeze

    def escape_to_breaker(value)
      value.gsub(MARC_BREAKER_SF_DELIMITER, MARC_BREAKER_SF_DELIMITER_ESCAPE).tr("\n", ' ')
    end

    def control_field_to_breaker(field)
      "=#{field.tag} #{escape_to_breaker(field.value)}"
    end

    def subfield_to_breaker(subfield)
      "$#{subfield.code}#{escape_to_breaker(subfield.value)}"
    end

    def datafield_to_breaker(field)
      ind1 = normalize_indicator field.indicator1
      ind2 = normalize_indicator field.indicator2
      all_subfields = field.subfields.map { |subfield| subfield_to_breaker(subfield) }.join
      "=#{field.tag} #{ind1}#{ind2}#{all_subfields}"
    end

    def normalize_indicator(ind)
      stripped = ind.strip
      if stripped.empty? || !valid_indicator?(stripped)
        '\\'
      else
        stripped
      end
    end

    def valid_indicator?(stripped)
      stripped.bytesize <= 1
    end

    def valid_tag?(tag)
      tag&.bytesize == 3
    end

    def leader_to_breaker(ldr)
      "=LDR #{ldr.rjust 24, ' '}"
    end

    attr_reader :original
end
