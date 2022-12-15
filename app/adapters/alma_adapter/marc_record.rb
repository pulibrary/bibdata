class AlmaAdapter
  # Adds functionality to an Alma::Bib to handle the various ways we manipulate
  # or access the MARC data for an individual record.
  class MarcRecord < SimpleDelegator
    attr_reader :bib, :marc_record
    # @param bib [Alma::Bib]
    # @param marc_record [MARC::Record]
    # @note We accept these two separately because parsing a bunch of MARC
    # records at once is more performant than doing one at a time, so it's
    # done before initializing this.
    def initialize(bib, marc_record)
      super(marc_record)
      @marc_record = marc_record
      @bib = bib
    end

    def suppressed?
      bib["suppress_from_publishing"] == "true"
    end

    def linked_record_ids
      linked_record_fields = marc_record.fields('774').select do |field|
        alma_bib_id?(field['w']) && field['t']
      end
      linked_record_fields.map do |field|
        field["w"]
      end
    end

    def enrich_with_item(item)
      item = ::AlmaAdapter::AlmaItem.new(item)
      marc_record.append(item.enrichment_876)
    end

    # Remove source record 852s and 86Xs, to reduce confusion when holding
    # data is added.
    def delete_conflicting_holding_data!
      marc_record.fields.delete_if { |f| ['852', '866', '867', '868'].include? f.tag }
    end

    # Remove source record 876s. These probably come from a publishing job, and
    # if we're calling this they're probably getting added back via
    # enrich_with_item to enable further processing.
    def delete_conflicting_item_data!
      marc_record.fields.delete_if { |f| ['876'].include? f.tag }
    end

    # @param holding [Alma::BibHolding | AlmaAdapter::AlmaHolding] Either a
    #   holding from the API or an already built `AlmaAdapter::AlmaHolding`. The
    #   holding may already be built in the case of
    #   `AlmaAdapter::ScsbDumpRecord`
    def enrich_with_holding(holding, recap: false)
      holding = ::AlmaAdapter::AlmaHolding.for(holding, recap:) unless holding.respond_to?(:marc_record_enrichment)
      marc_record.fields.concat(holding.marc_record_enrichment)
    end

    # Strips non-numeric tags for ReCAP, whose parser can't handle them.
    def strip_non_numeric!
      marc_record.fields.delete_if do |field|
        # tag with non numeric character
        field.tag.scan(/^(\s|\D+)/).present?
      end
    end

    # Pass a specific field code to check if it is an alma id.
    def alma_bib_id?(code)
      code.to_s.start_with?("99") && code.to_s.end_with?("06421")
    end
  end
end
