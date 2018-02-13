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
    def clean(value)
      return value unless /\?.+?%/.match?(value)
      cleaned = URI.decode_www_form_component(value)
      return cleaned unless /\?.+?%/.match?(value)
      clean(cleaned) # Recurse if there is more to be decoded
    end
end
