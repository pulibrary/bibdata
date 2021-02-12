class AlmaAdapter
  # Composite object for a set of items. Wraps up functionality for summarizing
  # all the items of a specific bib.
  class BibItemSet
    include Enumerable

    attr_reader :items, :adapter
    delegate :get_bib_record, to: :adapter
    # @param [Array<AlmaAdapter::AlmaItem>] items Array of items to wrap up.
    # @param [AlmaAdapter] adapter
    def initialize(items:, adapter:)
      @items = items
      @adapter = adapter
    end

    def each(&block)
      items.each(&block)
    end

    # @return [Hash] of locations/ holdings/ items data
    def holding_summary
      location_grouped = items.group_by(&:composite_location)
      location_grouped.map do |location_code, location_items|
        holdings = location_items.group_by(&:holding_id).map do |holding_id, holding_items|
          {
            "holding_id" => holding_id,
            "call_number" => holding_items.first.call_number,
            "items" => holding_items.map(&:as_json)
          }.compact
        end
        [location_code, holdings]
      end.to_h
    end
  end
end
