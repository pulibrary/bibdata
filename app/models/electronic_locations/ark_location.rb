module ElectronicLocations
  # Model for electronic location subfield values for ARKs
  # (ARKs are persistent URL's for resources on the WWW)
  # @see https://confluence.ucop.edu/display/Curation/ARK
  class ARKLocation < OnlineLocation
    # Constructor
    # @param value [URI::ARK, String] the ARK URI
    def initialize(value:)
      ark_value = value.is_a?(URI::ARK) ? value : URI::ARK.parse(url: value)
      super(value: ark_value)
    end
  end
end
