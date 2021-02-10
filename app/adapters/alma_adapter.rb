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
    bib_item_set = Alma::BibItem.find(id, opts).map { |item| AlmaAdapter::AlmaItem.new(item) }
    bib_item_set = AlmaAdapter::BibItemSet.new(items: bib_item_set, adapter: self)
    bib_item_set.holding_summary
  end

  private

    def apikey
      Rails.configuration.alma[:read_only_apikey]
    end
end
