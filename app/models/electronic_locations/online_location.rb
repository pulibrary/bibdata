module ElectronicLocations
  # Model for electronic location subfield values for online locations
  class OnlineLocation
    # Constructor
    # @param value [URI::Generic, String] the URI
    def initialize(value:)
      parsed_value = value.is_a?(URI::Generic) ? value : URI.parse(value)
      @value = parsed_value
    end
  end
end
