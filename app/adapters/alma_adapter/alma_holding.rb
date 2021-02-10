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

    def holding_note
      holding_record.fields("866").map do |field|
        field["a"]
      end.select(&:present?)
    end
  end
end
