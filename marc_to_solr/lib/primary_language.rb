# methods to assist with the calculation of the language_iana_primary_s field
class PrimaryLanguage
  # There is one 008 field.
  # https://www.loc.gov/marc/bibliographic/bd008.html
  def excluded_values(value:)
    ["zxx", "mul", "sgn", "und", "|||"].include?(value) || value&.match(/\s{3,}/)
  end

  def language_008(record)
    record.fields('008').map { |f| f.value[35..37] }.compact.first
  end

  def language_008_valid(record)
    value008 = language_008(record)
    return if excluded_values(value: value008)
    value008
  end

  # There can be more than one 041a
  def language_041a(record)
    record.fields('041').map { |f| f.subfields.map { |m| m.value if m.code == 'a' } }.flatten.compact.uniq
  end

  def language_041a_valid(record)
    return unless language_041a(record).present?
    result = []
    language_041a(record).each do |m|
      next if excluded_values(value: m)
      result << m
    end
    result.first
  end

  # There can be more than one 041d
  def language_041d(record)
    record.fields('041').map { |f| f.subfields.map { |m| m.value if m.code == 'd' } }.flatten.compact.uniq
  end

  def language_041d_valid(record)
    return unless language_041d(record).present?
    result = []
    language_041d(record).each do |m|
      next if excluded_values(value: m)
      result << m
    end
    result.first
  end

  def iso_639_language(language_value:)
    return if ISO_639.find(language_value).nil?
    if ISO_639.find(language_value).alpha2.empty?
      language_value
    else
      ISO_639.find(language_value).alpha2
    end
  end
end
