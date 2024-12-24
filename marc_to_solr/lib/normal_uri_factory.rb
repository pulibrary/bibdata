# Class for building normalized URIs
class NormalUriFactory
  # Constructor
  # @param value [String] String value for the URL
  def initialize(value:)
    @parser = URI::DEFAULT_PARSER
    @value = clean(value)
  end

  # Build the normalized URI
  # @return [URI::Generic] the URI Object for the resource
  def build
    URI.parse(@value)
  end

  private

    # Clean the URL value
    # @param value [String] String value for the URL
    def clean(value)
      return value if /#.+/.match?(value)

      @parser.escape(@parser.unescape(value).scrub)
    end
end
