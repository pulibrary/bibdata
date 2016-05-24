# A utility class to get all the 6XX $v and $x, which
# are used over and over again in the format finder
class XV6XX

  # Find all the 6XXxv values in the given record
  # @param [MARC::Record] record
  def initialize(record)
    @vals = []
    record.fields('600'..'699').each do |f|
      f.each do |sf|
        @vals << sf.value if %[x v].include?(sf.code)
      end
    end
  end

  # Do any of the 6XXxv values match the given
  # regex?
  # @param [Regexp] regex The regex to match
  # @return [Boolean] Does the given regexp match at least one value?
  def match?(regex)
    return @vals.grep(regex).size > 0
  end

end
