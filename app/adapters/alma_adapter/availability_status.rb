class AlmaAdapter
  class AvailabilityStatus
    # @param bib [Alma::Bib]
    def self.from_bib(bib:)
      new(bib: bib)
    end

    attr_reader :bib
    def initialize(bib:)
      @bib = bib
    end

    def to_h
      holdings.each_with_object({}) do |holding, acc|
        acc[holding["holding_id"]] = holding_summary(holding)
      end
    end

    def holding_summary(holding)
      {
        more_items: holding["total_items"].to_i > 1,
        item_id: item_data[holding["holding_id"]]&.first&.item_data&.fetch("pid", nil)
      }
    end

    def item_data
      @item_data ||= Alma::BibItem.find(bib.id).items.group_by do |item|
        item["holding_data"]["holding_id"]
      end
    end

    def marc_record
      @marc_record ||= MARC::XMLReader.new(StringIO.new(bib.response["anies"].join(""))).to_a.first
    end

    def holdings
      @availability_response ||= Alma::AvailabilityResponse.new(Array.wrap(bib)).availability[bib.id][:holdings]
    end
  end
end
