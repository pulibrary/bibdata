# Class for building normalized URIs
class NormalUriFactory

  # Constructor
  # @param value [String] String value for the URL
  def initialize(value:)
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
      return value if value =~ /#.+/
      URI.escape(URI.unescape(value).scrub)
    end
end
