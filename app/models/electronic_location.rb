# Model for electronic location (MARC 856) fields
# @see https://www.loc.gov/marc/bibliographic/bd856.html
class ElectronicLocation

  # Constructor
  # @param access_method [String] code for the access method
  # @param relationship [String] code for the relationship
  # @param subfields [Array<Hash>] subfield Hashes
  # @param holdings [Array<Holding>] holding values
  # @param iiif_manifest_uris [Array<IIIFManifestURI>] IIIF manifests
  def initialize(access_method:, relationship:, subfields:, holdings:, iiif_manifest_uris:)
    @access_method = access_method
    @relationship = relationship
    @subfields = subfields
    index_holdings!(holdings)
    @manifests = iiif_manifest_uris.map { |uri| uri.to_s }
  end

  # Returns the first sub-field value containing an ARK URL
  # This performs a full search for the ARK URI regardless of the subfield code
  # @return [Array<String>] the ARK URLs
  def identifiers
    @subfields.select do |subfield|
      subfield.values.find { |value| /arks\.princeton\.edu/.match(value) }.present?
    end.map { |subfield| subfield[ElectronicLocations::SubfieldCodes::URI] }
  end

  private

    # Index the electronic locations by labels
    # @param holdings [Holding] an array of electronic holdings
    # @param [Hash] a Hash of Holdings indexed by their identifiers
    def index_holdings!(holdings)
      @holdings = {}
      holdings.each do |holding|
        @holdings[holding.id] = holding.to_s
      end
    end
end
