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
    res.body.force_encoding("utf-8")
  end

  # @param id [String]. e.g id = "991227850000541"
  # @return [Hash] of locations/ holdings/ items data
  def get_items_for_bib(id)
    opts = { limit: 100, expand: "due_date_policy,due_date", order_by: "library", direction: "asc" }
    bib_item_set = Alma::BibItem.find(id, opts)
    holding_ids = bib_item_set.map { |item| item.holding_data["holding_id"] }.uniq
    notes_by_holding = bib_item_holding_notes(id, holding_ids)
    format_bib_items(bib_item_set, notes_by_holding)
  end

  # @param [Alma::BibItemSet]
  # @param [Hash<String, Array>] hash with holding id as key and notes as values
  # @return [Hash] of locations/ holdings/ items data
  def format_bib_items(bib_item_set, notes_by_holding)
    location_grouped = bib_item_set.group_by(&:location)
    location_grouped.each_with_object({}) do |(location_code, bib_items_array), location|
      location_value_array = []
      holdings = bib_items_array.group_by { |bi| bi["holding_data"]["holding_id"] }
      holdings.each_pair do |holding_id, items_array|
        location_value_array << format_holding(items_array, notes_by_holding[holding_id])
      end
      location[location_code] = location_value_array
    end
  end

  # @param holding_items_array [Array]
  # @return [Hash] of holdings
  def format_holding(holding_items_array, notes)
    {
      "holding_id" => holding_items_array.first.holding_data["holding_id"],
      "call_number" => holding_items_array.first.holding_data["call_number"],
      "notes" => notes,
      "items" => holding_items_array.each_with_index.map { |bib_item, idx| format_item(bib_item, idx) }
    }.compact
  end

  def format_item(bib_item, _idx)
    bib_item.item["item_data"].merge(
      "id" => bib_item.item["item_data"]["pid"],
      "copy_number" => bib_item.item["holding_data"]["copy_id"].to_i,
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
      Rails.configuration.alma[:read_only_apikey]
    end

    # @param mms_id [String]. e.g id = "991227850000541"
    # @param all_holding_ids [Array<String>]
    # @return [Hash<String, Array>] hash with holding id as key and notes as values
    def bib_item_holding_notes(mms_id, all_holding_ids)
      notes_from_bib_record = holding_notes_from_bib_record(mms_id)

      # Get list of holding ids not included in bib record AVA fields
      missing_holding_ids = all_holding_ids - notes_from_bib_record.keys

      # Bib record AVA fields do not include the holding ID for temporary holding locations.
      # We have to fetch notes for these holdings individually using their 866
      # value.
      notes_from_holdings = holding_notes_from_holding_records(mms_id, missing_holding_ids)

      # Return all notes
      notes_from_bib_record.merge(notes_from_holdings)
    end

    # Get notes from AVA subfields on bib record
    # @param mms_id [String]. e.g id = "991227850000541"
    # @param [Hash<String, Array>] hash with holding id as key and notes as values
    def holding_notes_from_bib_record(mms_id)
      record = get_bib_record(mms_id)
      return {} unless record&.try(:fields)
      notes_by_holding = {}
      ava_subfields = record.fields.select { |f| f.tag == "AVA" }.select { |s| s.codes.include? "t" }
      ava_subfields.each do |subfield|
        holding_id = subfield["8"]
        note = subfield["t"]
        notes_by_holding[holding_id] = notes_by_holding.fetch(holding_id, []) << note
      end

      notes_by_holding
    end

    # Get notes from holding records
    # @param id [String]. e.g id = "991227850000541"
    # @param [Hash<String, Array>] hash with holding id as key and notes as values
    def holding_notes_from_holding_records(mms_id, holding_ids)
      notes_by_holding = {}
      holding_ids.each do |holding_id|
        holding_record = Alma::BibHolding.find(mms_id: mms_id, holding_id: holding_id)
        xml_str = holding_record.holding.fetch("anies", []).first
        xml_doc = Nokogiri::XML(xml_str)
        field_866a = xml_doc.xpath('//record/datafield[@tag="866"]/subfield[@code="a"]')
        next if field_866a.empty?
        notes_by_holding[holding_id] = field_866a.map(&:text)
      end

      notes_by_holding
    end
end
