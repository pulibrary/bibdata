module ElectronicLocations
  # Model for electronic location subfield values for holdings
  # (Holdings are URL's for resources with an additional identifier)
  class Holding < OnlineLocation
    attr_reader :id
    # Constructor
    # @param id [String] the identifier for the holding
    # @param value [URI::Generic, String] the URI
    def initialize(id:, value:)
      @id = id
      super(value: value)
    end
  end
end
