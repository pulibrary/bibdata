class AlmaAdapter
  class BibItemSet
    include Enumerable

    attr_reader :items, :adapter
    delegate :get_bib_record, to: :adapter
    def initialize(items:, adapter:)
      @items = items
      @adapter = adapter
    end

    def each(&block)
      items.each(&block)
    end

    def holding_ids
      @holding_ids ||= items.map { |item| item.holding_data["holding_id"] }.uniq
    end

    def mms_id
      items[0]&.mms_id
    end

    def bib_record
      @bib_record ||= get_bib_record(mms_id)
    end

    # @return [Hash<String, Array>] hash with holding id as key and notes as values
    def holding_notes
      return @holding_notes if @holding_notes.present?
      notes_from_bib_record = bib_record&.holding_notes || {}

      # Get list of holding ids not included in bib record AVA fields
      missing_holding_ids = holding_ids - notes_from_bib_record.keys

      # Bib record AVA fields do not include the holding ID for temporary holding locations.
      # We have to fetch notes for these holdings individually using their 866
      # value.
      notes_from_holdings = holding_notes_from_holding_records(missing_holding_ids)

      # Return all notes
      @holding_notes ||= notes_from_bib_record.merge(notes_from_holdings)
    end

    # Get notes from holding records
    def holding_notes_from_holding_records(holding_ids)
      notes_by_holding = {}
      holding_ids.each do |holding_id|
        holding_record = AlmaAdapter::AlmaHolding.for(Alma::BibHolding.find(mms_id: mms_id, holding_id: holding_id))
        next unless holding_record.holding.holding.present?
        notes_by_holding[holding_id] = holding_record.holding_note if holding_record.holding_note.present?
      end

      notes_by_holding
    end

    # @return [Hash] of locations/ holdings/ items data
    def holding_summary
      location_grouped = items.group_by(&:composite_location)
      location_grouped.map do |location_code, location_items|
        holdings = location_items.group_by(&:holding_id).map do |holding_id, holding_items|
          {
            "holding_id" => holding_id,
            "call_number" => holding_items.first.call_number,
            "notes" => holding_notes[holding_id],
            "items" => holding_items.map(&:as_json)
          }.compact
        end
        [location_code, holdings]
      end.to_h
    end
  end
end
