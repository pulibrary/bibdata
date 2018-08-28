module ElectronicLocations
  # Model for electronic location subfield values for online locations which are IIIF manifests
  # @see http://iiif.io/api/presentation/2.0/#manifest
  class IIIFManifestURI < OnlineLocation
    attr_reader :ark
    # Constructor
    # @param ark [URK::ARK, String] the ARK URI
    # @param value [URI::Generic, String] the manifest URI
    def initialize(ark:, value:)
      ark_uri = ark.to_s
      @ark = ark_uri
      super(value: value)
    end
  end
end
