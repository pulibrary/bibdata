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
      holding_item_data = item_data[holding["holding_id"]]
      status = Status.new(bib: bib, holding_item_data: holding_item_data, holding: holding)
      {
        more_items: holding["total_items"].to_i > 1,
        item_id: holding_item_data&.first&.item_data&.fetch("pid", nil),
        location: "#{holding['library_code']}-#{holding['location_code']}",
        copy_number: holding_item_data&.first&.holding_data&.fetch('copy_id', ""),
        label: holding['library'],
        status: status.to_s
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

    def holding(holding_id:)
      holdings.find {|h| h["holding_id"] == holding_id }
    end

    def get_holding_items(holding_id)
      res = connection.get(
        "bibs/#{bib.id}/holdings/#{holding_id}/items?format=json",
        apikey: apikey
      )
      data = JSON.parse(res.body.force_encoding("utf-8")) || {}
      data["item"] || []
    end

    private

      # This method won't be needed once/if we move get_holding_items() to the Alma gem.
      def connection
        AlmaAdapter::Connector.connection
      end

      # This method won't be needed once/if we move get_holding_items() to the Alma gem.
      def apikey
        Rails.configuration.alma[:read_only_apikey]
      end
  end
end
