module ElectronicLocations
  # Model for electronic location subfield values for online locations which are IIIF manifests
  # @see http://iiif.io/api/presentation/2.0/#manifest
  class IIIFManifestURI < OnlineLocation
    attr_reader :ark
    # Constructor
    # @param ark [URK::ARK, String] the ARK URI
    # @param value [URI::Generic, String] the manifest URI
    def initialize(ark:, value:)
      ark_uri = ark.is_a?(URI::ARK) ? ark : parse(ark)
      @ark = ark_uri
      super(value: value)
    end

    private

      # Parse a string into an ARK object
      # @param ark_value [String] the ARK string
      # @return [URI::ARK] the ARK object
      def parse(ark_value)
        URI::ARK.parse(url: ark_value)
      end
  end
end
