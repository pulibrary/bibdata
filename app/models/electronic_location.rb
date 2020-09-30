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
    @manifests = iiif_manifest_uris.map(&:to_s)
    @iiif_manifest_uris = iiif_manifest_uris
  end

  # Returns the subfield value containing an ARK URL
  # @return [Array<String>] the ARK URLs
  def identifiers
    iiif_manifest_arks + @subfields.select do |subfield|
      subfield.key?(ElectronicLocations::SubfieldCodes::URI) && /arks\.princeton\.edu/.match(subfield[ElectronicLocations::SubfieldCodes::URI])
    end.map { |subfield| subfield[ElectronicLocations::SubfieldCodes::URI] }
  end

  def uri
    @subfields.flat_map { |x| x["u"] }.compact.first
  end

  def label
    @subfields.flat_map { |x| x["y"] }.compact.first || uri
  end

  private

    def iiif_manifest_arks
      @iiif_manifest_arks ||= @iiif_manifest_uris.map(&:ark).map(&:to_s)
    end

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
