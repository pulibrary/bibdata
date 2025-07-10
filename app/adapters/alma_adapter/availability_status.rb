class AlmaAdapter
  class AvailabilityStatus
    # @param bib [Alma::Bib]
    def self.from_bib(bib:)
      new(bib:)
    end

    attr_reader :bib

    def initialize(bib:, deep_check: false)
      @bib = bib
      @deep_check = deep_check
    end

    # Returns availability information for each of the holdings in the Bib record.
    def bib_availability
      sequence = 0
      holdings.each_with_object({}) do |holding, acc|
        sequence += 1
        status = holding_status(holding:)
        acc[status[:id]] = status unless status.nil?
      end
    end

    # Returns availability information for each of the holdings in the Bib record.
    # Notice that although we return the information by holding, we drill into item
    # information to get details.
    def bib_availability_from_items
      availability = {}
      item_data.each do |holding_id, items|
        next if items.count == 0

        # Process all the items for the holding and keep the "status" information from the last one.
        # Notice that we also gather enough information to determine whether the holding as a whole
        # is available, not available, or some items available.
        all_available = true
        none_available = true
        items.each do |item|
          alma_item = AlmaAdapter::AlmaItem.new(Alma::BibItem.new(item.item))
          status = holding_status_from_item(alma_item)
          availability[holding_id] = status
          all_available &&= status[:status_label] == 'Available'
          none_available &&= status[:status_label] == 'Unavailable'
        end

        # Update the availability's status_label of the holding as a whole.
        holding_availability = if all_available
                                 'Available'
                               elsif none_available
                                 Flipflop.change_status? ? 'Request' : 'Unavailable'
                               else
                                 Flipflop.change_status? ? 'Some Available' : 'Some items not available'
                               end
        availability[holding_id][:status_label] = holding_availability
      end
      availability
    end

    def holding_status(holding:)
      # Ignore electronic and digital records
      return nil if holding['inventory_type'] != 'physical'

      location_info = location_record(holding)
      status_label = Status.new(bib:, holding:, aeon: aeon?(location_info)).to_s
      status = {
        on_reserve: AlmaItem.reserve_location?(holding['library_code'], holding['location_code']) ? 'Y' : 'N',
        location: holding_location_code(holding),
        label: holding_location_label(holding, location_info),
        status_label:,
        copy_number: nil,
        temp_location: false,
        id: holding['holding_id']
      }

      if holding['holding_id'].nil?
        holding['holding_id'] = "#{holding['library_code']}$#{holding['location_code']}"
        # The ALma call from the Alma::AvailabilityResponse returns holding in temp_location with holding_id nil
        # see https://github.com/tulibraries/alma_rb/blob/affabad4094bc2abf0e8546b336d2a667d5ffab5/lib/alma/bib_item.rb#L53
        # In this case we create a holding_id using the name of the 'temporary_library$temporary_location'
        status[:id] = holding['holding_id']
        status[:temp_location] = true
      end

      status
    end

    # @param alma_item [AlmaAdapter::AlmaItem]
    def holding_status_from_item(alma_item)
      {
        on_reserve: alma_item.on_reserve? ? 'Y' : 'N',
        location: alma_item.composite_location_display,
        label: alma_item.composite_location_label_display,
        status_label: alma_item.calculate_status[:code],
        copy_number: alma_item.copy_number,
        temp_location: alma_item.in_temp_location?,
        id: alma_item.holding_id
      }
    end

    def to_h
      holdings.each_with_object({}) do |holding, acc|
        acc[holding['holding_id']] = holding_summary(holding)
      end
    end

    def holding_summary(holding)
      holding_item_data = item_data[holding['holding_id']]
      location_info = location_record(holding)
      status = Status.new(bib:, holding:, aeon: aeon?(location_info))
      {
        item_id: holding_item_data&.first&.item_data&.fetch('pid', nil),
        location: "#{holding['library_code']}-#{holding['location_code']}",
        copy_number: holding_item_data&.first&.holding_data&.fetch('copy_id', ''),
        label: holding_location_label(holding, location_info),
        status: status.to_s
      }
    end

    def item_data
      return @item_data if @item_data

      options = { timeout: 10 }
      message = "All items for #{bib.id}"
      items = AlmaAdapter::Execute.call(options:, message:) do
        # This method DOES issue a separate call to the Alma API to get item information.
        # Internally this call passes "ALL" to ExLibris to get data for all the holdings
        # in the current bib record.
        opts = { order_by: 'enum_a' }
        Alma::BibItem.find(bib.id, opts).items
      end

      @item_data = items.group_by do |item|
        item['holding_data']['holding_id']
      end
    end

    def marc_record
      @marc_record ||= MARC::XMLReader.new(StringIO.new(bib.response['anies'].join(''))).to_a.first
    end

    def holdings
      # This method does NOT issue a separate call to the Alma API to get the information, instead it
      # extracts the availability information (i.e. the AVA and AVE fields) from the bib record.
      # If temp_location is true cannot get holding_id from this call because of https://github.com/tulibraries/alma_rb/blob/affabad4094bc2abf0e8546b336d2a667d5ffab5/lib/alma/bib_item.rb#L53
      @availability_response ||= Alma::AvailabilityResponse.new(Array.wrap(bib)).availability[bib.id][:holdings]
    end

    def holding(holding_id:)
      holdings.find { |h| h['holding_id'] == holding_id }
    end

    # Returns all the items for a given holding_id in the current bib.
    # This is a more specific version of `item_data`.
    #
    # If the holding has more than ITEMS_PER_PAGE items the Alma gem will automatically
    # make multiple calls to the Alma API.
    def holding_item_data(holding_id:)
      data = nil
      options = { enable_loggable: true, timeout: 10 }
      message = "Items for bib: #{bib.id}, holding_id: #{holding_id}"
      AlmaAdapter::Execute.call(options:, message:) do
        opts = { limit: Alma::BibItemSet::ITEMS_PER_PAGE, holding_id:, order_by: 'enum_a' }
        items = Alma::BibItem.find(bib.id, opts).all.map { |item| AlmaAdapter::AlmaItem.new(item) }
        data = { items:, total_count: items.count }
      end
      data
    end

    private

      # Returns the extra location information that we store in the local database
      def location_record(holding)
        HoldingLocation.find_by(code: holding_location_code(holding))
      end

      # The status label retrieves the value from holding_location.label
      # which is equivalent to the alma external_name value
      def holding_location_label(holding, location_record)
        label = location_record&.label
        [holding['library'], label].select(&:present?).join(' - ')
      end

      def holding_location_code(holding)
        [holding['library_code'], holding['location_code']].join('$')
      end

      def aeon?(location_record)
        location_record&.aeon_location
      end
  end
end
