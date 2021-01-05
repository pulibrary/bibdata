class AlmaAdapter
  attr_reader :connection
  def initialize(connection: AlmaAdapter::Connector.connection)
    @connection = connection
  end

  # Get /almaws/v1/bibs Retrieve bibs
  # @param id [String] e.g. id = "991227830000541"
  # @see https://developers.exlibrisgroup.com/console/?url=/wp-content/uploads/alma/openapi/bibs.json#/Catalog/get%2Falmaws%2Fv1%2Fbibs Values that could be passed to the alma API
  # get one bib record is supported in the bibdata UI and in the bibliographic_controller
  # @return [MARC::Record]
  def get_bib_record(id)
    get_bib_records([id])&.first
  end

  # Get /almaws/v1/bibs Retrieve bibs
  # @param ids [Array] e.g. ids = ["991227850000541","991227840000541","99222441306421"]
  # @see https://developers.exlibrisgroup.com/console/?url=/wp-content/uploads/alma/openapi/bibs.json#/Catalog/get%2Falmaws%2Fv1%2Fbibs Values that could be passed to the alma API
  # @return [Array<MARC::Record>]
  def get_bib_records(ids)
    bibs = Alma::Bib.find(Array.wrap(ids), expand: ["p_avail", "e_avail", "d_avail", "requests"].join(",")).each
    AlmaAdapter::MarcResponse.new(bibs: bibs).unsuppressed_marc
  rescue Alma::StandardError
    []
  end

  def get_availability(ids:)
    bibs = Alma::Bib.find(Array.wrap(ids), expand: ["p_avail", "e_avail", "d_avail", "requests"].join(",")).each
    AvailabilityStatus.from_bib(bib: bibs&.first).to_h
  end

  # Returns list of holding records for a given MMS
  # @param id [string]. e.g id = "991227850000541"
  def get_holding_records(id)
    res = connection.get(
      "bibs/#{id}/holdings",
      apikey: apikey
    )
    res.body
  end

  # @param id [string]. e.g id = "991227850000541"
  # @return [Hash] of locations/ holdings/ items data
  def get_items_for_bib(id)
    opts = { limit: 100, expand: "due_date_policy,due_date", order_by: "library", direction: "asc" }
    bib_item_set = Alma::BibItem.find(id, opts)
    format_bib_items(bib_item_set)
  end

  # @param [Alma::BibItemSet]
  # @return [Hash] of locations/ holdings/ items data
  def format_bib_items(bib_item_set)
    location_grouped = bib_item_set.group_by(&:location)
    location_grouped.each_with_object({}) do |(location_code, bib_items_array), location|
      location_value_array = []
      holdings = bib_items_array.group_by { |bi| bi["holding_data"]["holding_id"] }
      holdings.each_pair do |_holding_id, items_array|
        location_value_array << format_holding(items_array)
      end
      location[location_code] = location_value_array
    end
  end

  # @param holding_items_array [Array]
  # @return [Hash] of holdings
  def format_holding(holding_items_array)
    {
      "holding_id" => holding_items_array.first.holding_data["holding_id"],
      "call_number" => holding_items_array.first.holding_data["call_number"],
      "items" => holding_items_array.each_with_index.map { |bib_item, idx| format_item(bib_item, idx) }
    }
  end

  def format_item(bib_item, idx)
    bib_item.item["item_data"].merge(
      "id" => bib_item.item["item_data"]["pid"],
      "copy_number" => bib_item.item["holding_data"]["copy_id"].to_i,
      "item_sequence_number" => idx + 1,
      "temp_location" => temp_location(bib_item),
      "perm_location" => perm_location(bib_item),
      "item_type" => item_type(bib_item)
    )
  end

  def item_type(bib_item)
    item_data = bib_item.item["item_data"]
    return "Gen" unless item_data["policy"]["value"].present?
    item_data["policy"]["value"]
  end

  def temp_location(bib_item)
    holding_data = bib_item.item["holding_data"]
    return nil unless holding_data["in_temp_location"]
    "#{holding_data['temp_library']['value']}-#{holding_data['temp_location']['value']}"
  end

  def perm_location(bib_item)
    item_data = bib_item.item["item_data"]
    "#{item_data['library']['value']}-#{item_data['location']['value']}"
  end

  private

    def apikey
      Rails.configuration.alma[:bibs_read_only]
    end
end
