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

    # Returns availability information for each of the holdings in the Bib record.
    def bib_availability
      sequence = 0
      availability = holdings.each_with_object({}) do |holding, acc|
        sequence += 1
        status = holding_status(holding: holding, sequence: sequence)
        acc[status[:id]] = status if status.nil?
      end
      availability
    end

    # Returns availability information for each of the holdings in the Bib record.
    # Notice that although we return the information by holding, we drill into item
    # information to get details.
    def bib_availability_from_items
      availability = {}
      item_data.each do |_key, value|
        next if value.count == 0
        raise StandardError.new, "Multiple items found under the same key" if value.count > 1
        alma_item = AlmaAdapter::AlmaItem.new(Alma::BibItem.new(value.first.item))
        status = holding_status_from_item(alma_item)
        raise StandardError.new, "Holding found more than once" if availability[alma_item.holding_id]
        availability[alma_item.holding_id] = status
      end
      availability
    end

    def holding_status(holding:, sequence:)
      # Ignore electronic and digital records
      return nil if holding["inventory_type"] != "physical"

      status_label = Status.new(bib: bib, holding: holding, holding_item_data: nil).to_s
      status = {
        on_reserve: "N",
        location: holding["library_code"] + "$" + holding["location_code"],
        label: holding["location"],
        status_label: status_label,
        copy_number: nil,
        cdl: false,
        temp_location: holding["holding_id"].nil?,
        id: holding["holding_id"]
      }

      # Some physical resources can have a nil ID when they are in a temporary location
      # because Alma does not tells us the holding_id that they belong to. For those
      # records we create a fake ID so that we can handle multiple holdings with this
      # condition.
      status[:id] = "fake_id_#{sequence}" if holding["holding_id"].nil?

      # Notice that we only check if a holding is available via CDL when necessary
      # because it requires an extra (slow-ish) API call.
      status[:cdl] = cdl_holding?(holding["holding_id"]) if status[:status_label] == "Unavailable"

      status
    end

    def holding_status_from_item(alma_item)
      status = {
        on_reserve: "N",
        location: alma_item.composite_location_display,
        label: alma_item.composite_location_label_display,
        status_label: alma_item.calculate_status[:code],
        copy_number: alma_item.copy_number,
        cdl: alma_item.cdl?,
        temp_location: alma_item.in_temp_location?,
        id: alma_item.holding_id
      }
      status
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
        item_id: holding_item_data&.first&.item_data&.fetch("pid", nil),
        location: "#{holding['library_code']}-#{holding['location_code']}",
        copy_number: holding_item_data&.first&.holding_data&.fetch('copy_id', ""),
        label: holding['library'],
        status: status.to_s
      }
    end

    def item_data
      # This method DOES issue a separate call to the Alma API to get item information.
      # Internally this call passes "ALL" to ExLibris to get data for all the holdings
      # in the current bib record.
      @item_data ||= Alma::BibItem.find(bib.id).items.group_by do |item|
        item["holding_data"]["holding_id"]
      end
    end

    def marc_record
      @marc_record ||= MARC::XMLReader.new(StringIO.new(bib.response["anies"].join(""))).to_a.first
    end

    def holdings
      # This method does NOT issue a separate call to the Alma API to get the information, instead it
      # extracts the availability information (i.e. the AVA and AVE fields) from the bib record.
      @availability_response ||= Alma::AvailabilityResponse.new(Array.wrap(bib)).availability[bib.id][:holdings]
    end

    def holding(holding_id:)
      holdings.find { |h| h["holding_id"] == holding_id }
    end

    # Returns all the items for a given holding_id in the current bib.
    # This is a more specific version of `item_data`.
    #
    # If the holding has more than ITEMS_PER_PAGE items the Alma gem will automatically
    # make multiple calls to the Alma API.
    def holding_item_data(holding_id:)
      data = nil
      alma_preserve_exception do
        opts = { limit: Alma::BibItemSet::ITEMS_PER_PAGE, holding_id: holding_id }
        items = Alma::BibItem.find(bib.id, opts).all.map { |item| AlmaAdapter::AlmaItem.new(item) }
        data = { items: items, total_count: items.count }
      end
      data
    end

    private

      def cdl_holding?(holding_id)
        cdl = false
        item_data[holding_id].each do |bib_item|
          if AlmaItem.new(bib_item).cdl?
            cdl = true
            break
          end
        end
        cdl
      end

      # In some instances the Alma gem hides the original exception and returns a string
      # (rather than a hash) with the error information. This beheavior prevents us from
      # handling PER_SECOND_THRESHOLD errors. In those instances we use this method to
      # force the Alma gem to preserve the original exception.
      def alma_preserve_exception
        cached_value = Alma.configuration.enable_loggable
        begin
          Alma.configure { |config| config.enable_loggable = true }
          yield
        ensure
          Alma.configure { |config| config.enable_loggable = cached_value }
        end
      end
  end
end
