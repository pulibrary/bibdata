# Factory for constructing ElectronicLocation Objects
class ElectronicLocationsFactory

  # Construct IIIFManifestURI Objects from Solr Document values
  # @param values [Hash] Solr Document values for links Hash by URL
  # @return [Array<IIIFManifestURI>]
  def self.parse_iiif_manifest_paths(values)
    values.map do |ark_url_key, iiif_manifest_path|
      ElectronicLocations::IIIFManifestURI.new(ark: ark_url_key, value: iiif_manifest_path)
    end
  end

  # Construct Holding Objects from Solr Document values
  # @param values [Hash] Solr Document values for links Hash by URL
  # @return [Array<Holding>]
  def self.parse_holdings(values)
    values.map do |holding_id, url_values|
      url_key = url_values.keys.first
      ElectronicLocations::Holding.new(id: holding_id, value: url_key)
    end
  end

  # Generate a Hash indexing the MARC subfield values for an electronic location field
  # @param holding_values [Hash] Solr Document values for URL's Hashed by holding ID
  # @param values [Hash] Solr Document values for links Hash by URL
  # @return [Hash]
  def self.parse_subfields(holding_values, values)
    subfields = []
    holding_values.each do |_holding_id, url_values|
      url_values.each do |url_key, url_labels|
        subfield = {}

        url_key = url_values.keys.first
        subfield[ElectronicLocations::SubfieldCodes::URI] = url_key
        subfield[ElectronicLocations::SubfieldCodes::LINK_TEXT] = url_labels.first
        subfield[ElectronicLocations::SubfieldCodes::PUBLIC_NOTE] = url_labels.last if url_labels.length > 1
        subfields << subfield
      end
    end

    values.each do |url_key, url_labels|
      subfield = {}
      subfield[ElectronicLocations::SubfieldCodes::URI] = url_key
      subfield[ElectronicLocations::SubfieldCodes::LINK_TEXT] = url_labels.first
      subfield[ElectronicLocations::SubfieldCodes::PUBLIC_NOTE] = url_labels.last if url_labels.length > 1
      subfields << subfield
    end

    subfields
  end

  # Factory method for constructing ElectronicLocation Objects
  # @param solr_doc [Hash] Solr Document values
  # @return [Array<ElectronicLocation>]
  def self.build(solr_doc)
    solr_values = solr_doc.fetch('electronic_access_1display', [])
    solr_values.map do |values|
      solr_value = values || '{}'
      electronic_access_1display = JSON.parse(solr_value)

      iiif_manifest_path_values = electronic_access_1display.delete('iiif_manifest_paths') || {}
      iiif_manifest_uris = parse_iiif_manifest_paths(iiif_manifest_path_values)

      holding_values = electronic_access_1display.delete('holding_record_856s') || {}
      holdings = parse_holdings(holding_values)

      subfields = parse_subfields(holding_values, electronic_access_1display)

      ElectronicLocation.new(access_method: ElectronicLocations::Indicators::HTTP,
                             relationship: ElectronicLocations::Relationships::VERSION,
                             subfields: subfields,
                             holdings: holdings, iiif_manifest_uris: iiif_manifest_uris)
    end
  end
end
