# Class modeling the ARK standard for URL's
# @see https://tools.ietf.org/html/draft-kunze-ark-18
class URI::ARK < URI::Generic
  attr_reader :nmah, :naan, :name

  ARK_REGEX = /\:\/\/(.+)\/ark\:\/(.+)\/(.+)\/?/
  PRINCETON_ARK_REGEX = /[\/?]ark\:\/88435\/(.+)\/?/

  # Constructs an ARK from a URL
  # @param url [URI::Generic] the URL for the ARK resource
  # @return [URI::ARK] the ARK
  def self.parse(url:)
    url = URI.parse(url) unless url.is_a? URI::Generic
    build(
      scheme: url.scheme,
      userinfo: url.userinfo,
      host: url.host,
      port: url.port,
      registry: url.registry,
      path: url.path,
      opaque: url.opaque,
      query: url.query,
      fragment: url.fragment
    )
  end

  # Validates whether or not a URL is an ARK URL
  # @param uri [URI::Generic] a URL
  # @return [TrueClass, FalseClass]
  def self.princeton_ark?(url:)
    return false if url.to_s.start_with?('http:http:')
    return false unless PRINCETON_ARK_REGEX.match(url.to_s)
    return false unless ARK_REGEX.match(url.to_s)
    true
  end

  # Constructor
  def initialize(*arg)
    super(*arg)
    extract_components!
  end

  private

    # Extract the components from the ARK URL into member variables
    def extract_components!
      raise StandardError, "Invalid ARK URL using: #{self.to_s}" unless self.class.princeton_ark?(url: self)
      m = ARK_REGEX.match(self.to_s)

      @nmah = m[1]
      @naan = m[2]
      @name = m[3]
    end
end
