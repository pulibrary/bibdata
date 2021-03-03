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

    # minimal summary of locations / holdings / items data used for bib_items
    # response
    # @param item_key_filter [String] keys to include in the items hash
    # @return [Hash] of locations/ holdings/ items data
    def holding_summary(item_key_filter: nil)
      location_grouped = items.group_by(&:composite_location)
      location_grouped.map do |location_code, location_items|
        holdings = location_items.group_by(&:holding_id).map do |holding_id, holding_items|
          {
            "holding_id" => holding_id,
            "call_number" => holding_items.first.call_number,
            "items" => holding_items_filter(holding_items.map(&:as_json), item_key_filter)
          }.compact
        end
        [location_code, holdings]
      end.to_h
    end

    private

      def holding_items_filter(items, filter)
        return items unless filter
        items.map do |h|
          h.keep_if do |k, _v|
            filter.include? k
          end
        end
      end
  end
end
