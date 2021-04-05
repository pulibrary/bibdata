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

  # Returns availability for one bib id
  def get_availability_one(id:)
    bibs = Alma::Bib.find(Array.wrap(id), expand: ["p_avail", "e_avail", "d_avail", "requests"].join(",")).each
    return nil if bibs.count == 0
    { bibs.first.id => AvailabilityStatus.new(bib: bibs.first).bib_availability }
  end

  # Returns availability for a list of bib ids
  def get_availability_many(ids:)
    bibs = Alma::Bib.find(Array.wrap(ids), expand: ["p_avail", "e_avail", "d_avail", "requests"].join(",")).each
    return nil if bibs.count == 0
    availability = bibs.each_with_object({}) do |bib, acc|
      acc[bib.id] = AvailabilityStatus.new(bib: bib).bib_availability
    end
    availability
  end

  def get_availability_holding(id:, holding_id:)
    # Fetch the bib record and get the information for the individual holding
    bibs = Alma::Bib.find(Array.wrap(id), expand: ["p_avail", "e_avail", "d_avail", "requests"].join(",")).each
    return nil if bibs.count == 0

    bib_status = AvailabilityStatus.from_bib(bib: bibs.first)
    marc_holding = bib_status.holding(holding_id: holding_id) || {}

    # Fetch the items for the holding and create the availability response
    availability = []
    # holding_items = get_holding_items(id, holding_id)["item"] || []
    bib_status.get_holding_items(holding_id).each do |item|
      item_data = item["item_data"] || {}
      holding_data = item["holding_data"] || {}

      location = item_data["location"] || {}
      library = item_data["library"] || {}
      if holding_data["in_temp_location"]
        # http://localhost:3000/bibliographic/9919392043506421/holdings/22105104420006421/availability.json
        library = holding_data["temp_library"] || {}
        location = holding_data["temp_location"] || {}
      end

      status_label = marc_holding["availability"]
      if status_label.nil?
        # TODO: Figure out if this is right.
        #     When the marc_holding is nil it seems that there is a a single holding in the bib but
        #     that holding does NOT have an ID, yet, I think for eresources that single holding
        #     seems to have the data that we need and therefore we could take the "availability"
        #     property from that holding.
        #     For an example see: http://localhost:3000/bibliographic/9919392043506421/holdings/22105104420006421/availability.json
        # For now use the data in the item.
        #
        # If we do use the item_data value we should normalize it so that it says "available"
        # rather than "Item in place".
        status_label = item_data["base_status"]["desc"]
      end

      policy = item_data["policy"] || {}
      item_av = {
        "barcode": item_data["barcode"],
        "id": item_data["pid"],
        "copy_number": holding_data["copy_id"],
        "status": nil,                                # ?? "Not Charged"
        "item_sequence_number": nil,                  # not used ??
        "on_reserve": nil,                            # ??
        "item_type": policy["value"],                 # Gen
        "pickup_location_id": location["value"],      # stacks
        "pickup_location_code": location["value"],    # stacks
        "patron_group_charged": nil,                  # ??
        "location": library["value"],                 # firestone
        "label": library["desc"],                     # Firestore Library
        "status_label": status_label                  # available
      }

      # Only populate the enum_display key if there is data.
      enum_string = enum_diplay(item_data)
      item_av["enum_display"] = enum_string unless enum_string.blank?

      # Only populate the chron_display key if there is data.
      chron_string = chron_display(item_data)
      item_av["chron_display"] = chron_string unless chron_string.blank?

      availability << item_av
    end
    availability
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
  # @return [AlmaAdapter::BibItemSet]
  def get_items_for_bib(id)
    opts = { limit: 100, expand: "due_date_policy,due_date", order_by: "library", direction: "asc" }
    bib_items = Alma::BibItem.find(id, opts).map { |item| AlmaAdapter::AlmaItem.new(item) }
    AlmaAdapter::BibItemSet.new(items: bib_items, adapter: self)
  end

  # @param record [AlmaAdapter::MarcRecord]
  # @return [String] date record was created e.g. "2019-10-18Z"
  def get_catalog_date_from_record(record)
    return nil if record.nil?

    ava = record.select { |f| f.tag == "AVA" }
    if ava.count > 0
      # Get the creation date from the physical items
      item_set = get_items_for_bib(record.bib.id)
      dates = item_set.items.map { |i| i["item_data"]["creation_date"] }.compact
      return dates.sort.first if dates.count > 0
    end

    # Note: For now we are not searching for the activation date in portfolios
    # indicated in the AVE fields.
    #
    # If needed we could use the alma/:mms_id/portfolios/:portfolio_id endpoint
    # to get this information one by one. ExLibris has indicated that this information
    # will also be available on the alma/:mms_id/portfolios endpoint around May/2021
    # (see https://3.basecamp.com/3765443/buckets/20717908/messages/3475344037)
    # which will result in one call per bib rather than one call per portfolio.

    # Default to the Bib record created date
    record.bib["created_date"]
  end

  private

    def apikey
      Rails.configuration.alma[:read_only_apikey]
    end

    # Voyager only had one field for enumeration but Alma has many.
    def enum_diplay(item_data)
      enums = []
      enums << item_data["enumeration_a"]
      enums << item_data["enumeration_b"]
      enums << item_data["enumeration_c"]
      enums << item_data["enumeration_d"]
      enums << item_data["enumeration_e"]
      enums << item_data["enumeration_f"]
      enums << item_data["enumeration_g"]
      enums << item_data["enumeration_h"]
      enums.reject(&:blank?).join(", ")
    end

    # Voyager only had one field for chronology but Alma has many.
    def chron_display(item_data)
      chrons = []
      chrons << item_data["chronology_i"]
      chrons << item_data["chronology_j"]
      chrons << item_data["chronology_k"]
      chrons << item_data["chronology_l"]
      chrons << item_data["chronology_m"]
      chrons.reject(&:blank?).join(", ")
    end
end
