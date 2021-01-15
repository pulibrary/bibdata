class AlmaAdapter
  class AlmaHolding
    def self.for(holding, recap: false)
      return new(holding) unless recap
      AlmaAdapter::RecapAlmaHolding.new(holding)
    end
    attr_reader :holding
    # @param item [Alma::BibHolding]
    def initialize(holding)
      @holding = holding
    end

    def marc_record_enrichment
      [
        enriched_852,
        prepend_holding_id(holding_record["856"]),
        prepend_holding_id(holding_record["866"]),
        prepend_holding_id(holding_record["867"])
      ].compact
    end

    def enriched_852
      prepend_holding_id(holding_record["852"])
    end

    def prepend_holding_id(field)
      return unless field
      field.tap do |f|
        f.subfields.unshift(MARC::Subfield.new('0', holding_id))
      end
    end

    def holding_record
      @holding_record ||=
        begin
          MARC::XMLReader.new(
            StringIO.new(
              holding["anies"].first
            )
          ).first
        end
    end

    def holding_id
      holding["holding_id"]
    end
  end
end
