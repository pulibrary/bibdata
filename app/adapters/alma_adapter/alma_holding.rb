class AlmaAdapter
  class AlmaHolding
    def self.for(holding, holding_record: nil, recap: false)
      return new(holding, holding_record:) unless recap
      AlmaAdapter::RecapAlmaHolding.new(holding, holding_record:)
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
        prepend_holding_id(holding_record.fields("866")),
        prepend_holding_id(holding_record.fields("867")),
        prepend_holding_id(holding_record.fields("868"))
      ].flatten.compact
    end

    def enriched_852
      prepend_holding_id(holding_record.fields("852"))
    end

    def prepend_holding_id(fields)
      return if fields.blank?
      fields.map do |field|
        field.tap do |f|
          # adds a new 0. in the notes Mark g. Change $8 subfields in 852, 866, 867, 868 to $0
          f.subfields.unshift(MARC::Subfield.new('0', holding_id))
        end
      end
    end

    # we are not going to use this for recap.
    def holding_record
      @holding_record ||=
        MARC::XMLReader.new(
            StringIO.new(
              holding["anies"].first
            )
          ).first
    end

    def holding_id
      holding["holding_id"]
    end
  end
end
