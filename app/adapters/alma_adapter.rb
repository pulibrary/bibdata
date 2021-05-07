class AlmaAdapter
  class ::Alma::PerSecondThresholdError < Alma::StandardError; end
  class ::Alma::NotFoundError < Alma::StandardError; end

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
  rescue Alma::StandardError => client_error
    errors = build_alma_errors(from: client_error)
    raise errors.first if !errors.empty? && errors.first.is_a?(Alma::PerSecondThresholdError)

    []
  end

  def get_availability(ids:)
    bibs = Alma::Bib.find(Array.wrap(ids), expand: ["p_avail", "e_avail", "d_avail", "requests"].join(",")).each
    AvailabilityStatus.from_bib(bib: bibs&.first).to_h
  end

  # Returns availability for one bib id
  def get_availability_one(id:, deep_check: false)
    bibs = Alma::Bib.find(Array.wrap(id), expand: ["p_avail", "e_avail", "d_avail", "requests"].join(",")).each
    return nil if bibs.count == 0

    av_info = AvailabilityStatus.new(bib: bibs.first).bib_availability

    temp_locations = av_info.any? { |_key, value| value[:temp_location] }
    if temp_locations && deep_check
      # We don't get enough information at the holding level for items located
      # in temporary locations. But if the client requests it we can drill into
      # the item information to get all the information (keep in mind that this
      # involves an extra API call that is slow-ish.)
      av_info = AvailabilityStatus.new(bib: bibs.first).bib_availability_from_items
    end

    { bibs.first.id => av_info }
  rescue Alma::StandardError => e
    handle_alma_error(client_error: e)
  end

  # Returns availability for a list of bib ids
  def get_availability_many(ids:)
    bibs = Alma::Bib.find(Array.wrap(ids), expand: ["p_avail", "e_avail", "d_avail", "requests"].join(",")).each
    return nil if bibs.count == 0
    availability = bibs.each_with_object({}) do |bib, acc|
      acc[bib.id] = AvailabilityStatus.new(bib: bib).bib_availability
    end
    availability
  rescue Alma::StandardError => e
    handle_alma_error(client_error: e)
  end

  def get_availability_holding(id:, holding_id:)
    # Fetch the bib record and get the information for the individual holding
    bibs = Alma::Bib.find(Array.wrap(id), expand: ["p_avail", "e_avail", "d_avail", "requests"].join(",")).each
    return nil if bibs.count == 0

    # Fetch the items for the holding and create
    # the availability response for each item
    bib_status = AvailabilityStatus.from_bib(bib: bibs.first)
    holding_items = bib_status.holding_item_data(holding_id: holding_id)
    holding_items[:items].map(&:availability_summary)
  rescue Alma::StandardError => e
    handle_alma_error(client_error: e)
  end

  # Returns list of holding records for a given MMS
  # @param id [string]. e.g id = "991227850000541"
  def get_holding_records(id)
    res = connection.get(
      "bibs/#{id}/holdings",
      apikey: apikey
    )

    res.body.force_encoding("utf-8") if validate_response!(response: res)
  end

  # @param id [String]. e.g id = "991227850000541"
  # @return [AlmaAdapter::BibItemSet]
  def get_items_for_bib(id)
    opts = { limit: Alma::BibItemSet::ITEMS_PER_PAGE, expand: "due_date_policy,due_date", order_by: "library", direction: "asc" }
    bib_items = Alma::BibItem.find(id, opts).all.map { |item| AlmaAdapter::AlmaItem.new(item) }

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

  def item_by_barcode(barcode)
    item = Alma::BibItem.find_by_barcode(barcode)
    if item["errorsExist"]
      # In this case although `item` is an object of type Alma::BibItem, its
      # content is really an HTTPartyResponse with the error information. :shrug:
      message = item.item.parsed_response.to_s
      error = message.include?("No items found") ? Alma::NotFoundError.new(message) : Alma::StandardError.new(message)
      handle_alma_error(client_error: error)
    end
    item
  end

  def holding_by_id(mms_id:, holding_id:)
    holding = Alma::BibHolding.find(mms_id: mms_id, holding_id: holding_id)
    if holding["errorsExist"]
      # In this case although `holding` is an object of type Alma::BibHolding, its
      # content is really an HTTPartyResponse with the error information. :shrug:
      error = Alma::StandardError.new(holding.holding.parsed_response.to_s)
      handle_alma_error(client_error: error)
    end
    holding
  end

  def find_user(patron_id)
    alma_preserve_exception do
      return Alma::User.find(patron_id)
    rescue Alma::StandardError => e
      # The Alma gem throws "not found" for all errors but only error code 401861
      # really represents a record not found.
      raise Alma::NotFoundError, "User #{patron_id} was not found" if e.message.include?('"errorCode":"401861"')
      handle_alma_error(client_error: e)
    end
  end

  private

    def apikey
      Rails.configuration.alma[:read_only_apikey]
    end

    def build_alma_error_from(json:)
      error = json.deep_symbolize_keys
      error_code = error[:errorCode]

      case error_code
      when "PER_SECOND_THRESHOLD"
        Alma::PerSecondThresholdError.new(error[:errorMessage])
      else
        Alma::StandardError.new(error[:errorMessage])
      end
    end

    def build_alma_errors_from(json:)
      error_list = json["errorList"]
      errors = error_list["error"]
      errors.map { |error| build_alma_error_from(json: error) }
    end

    def build_alma_errors(from:)
      message = from.message.gsub('=>', ':').gsub('nil', '"null"')
      parsed_message = JSON.parse(message)
      build_alma_errors_from(json: parsed_message)
    end

    def validate_response!(response:)
      return true if response.status == 200

      response_body = JSON.parse(response.body)
      errors = build_alma_errors_from(json: response_body)
      return true if errors.empty?

      raise(errors.first)
    end

    def handle_alma_error(client_error:)
      errors = build_alma_errors(from: client_error)
      raise errors.first if errors.first.is_a?(Alma::PerSecondThresholdError)
      raise client_error
    end

    # In some instances the Alma gem hides the original exception and returns a string
    # (rather than a hash) with the error information. This beheavior prevents us from
    # handling PER_SECOND_THRESHOLD errors. In those instances we use this method to
    # force the Alma gem to preserve the original exception.
    #
    # Notice that this method is duplicated in availability_status.rb. At some point
    # we might want to refactor this and have all calls to the Alma gem come through
    # alma_adapter.rb and remove the duplicate.
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
