class AlmaAdapter
  class AlmaHolding
    def self.for(holding, holding_record: nil, recap: false)
      return new(holding, holding_record: holding_record) unless recap
      AlmaAdapter::RecapAlmaHolding.new(holding, holding_record: holding_record)
    end
    attr_reader :holding
    # @param item [Alma::BibHolding]
    def initialize(holding, holding_record: nil)
      @holding = holding
      @holding_record = holding_record
    end

    def marc_record_enrichment
      [
        enriched_852,
        prepend_holding_id(holding_record.fields("856")),
        prepend_holding_id(holding_record.fields("866")),
        prepend_holding_id(holding_record.fields("867"))
      ].flatten.compact
    end

    def enriched_852
      prepend_holding_id(holding_record.fields("852"))
    end

    def prepend_holding_id(fields)
      return unless fields.present?
      fields.map do |field|
        field.tap do |f|
          f.subfields.unshift(MARC::Subfield.new('0', holding_id))
        end
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
