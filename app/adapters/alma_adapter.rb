require 'open-uri'

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
  # @return [AlmaAdapter::MarcRecord]
  def get_bib_record(id, show_suppressed: false)
    return nil unless /\A\d+\z/.match? id
    get_bib_records([id], show_suppressed:)&.first
  end

  # Get /almaws/v1/bibs Retrieve bibs
  # @param ids [Array] e.g. ids = ["991227850000541","991227840000541","99222441306421"]
  # @see https://developers.exlibrisgroup.com/console/?url=/wp-content/uploads/alma/openapi/bibs.json#/Catalog/get%2Falmaws%2Fv1%2Fbibs Values that could be passed to the alma API
  # @return [Array<AlmaAdapter::MarcRecord>]
  def get_bib_records(ids, show_suppressed: false)
    cql_query = show_suppressed ? "" : "alma.mms_tagSuppressed=false%20and%20"
    cql_query << ids.map { |id| "alma.mms_id=#{id}" }.join("%20or%20")
    sru_url = "#{Rails.configuration.alma['sru_url']}?"\
              "version=1.2&operation=searchRetrieve&"\
              "recordSchema=marcxml&query=#{cql_query}"\
              "&maximumRecords=#{ids.count}"
    MARC::XMLReader.new(URI(sru_url).open, parser: :nokogiri).map do |record|
      MarcRecord.new(nil, record)
    end
  end

  def get_availability(ids:)
    bibs = Alma::Bib.find(Array.wrap(ids), expand: ["p_avail", "e_avail", "d_avail", "requests"].join(",")).each
    AvailabilityStatus.from_bib(bib: bibs&.first).to_h
  end

  # Returns availability for one bib id
  def get_availability_one(id:, deep_check: false)
    get_availability_status = lambda do |bib|
      av_info = AvailabilityStatus.new(bib:, deep_check:).bib_availability
      temp_locations = av_info.any? { |_key, value| value[:temp_location] }
      if temp_locations && deep_check
        # We don't get enough information at the holding level for items located
        # in temporary locations. But if the client requests it we can drill into
        # the item information to get all the information (keep in mind that this
        # involves an extra API call that is slow-ish.)
        AvailabilityStatus.new(bib:).bib_availability_from_items
      else
        av_info
      end
    end

    Alma::Bib.find(Array.wrap(id), expand: ["p_avail", "e_avail", "d_avail", "requests"].join(","))
             .each
             .lazy
             .map { |bib| { bib.id => get_availability_status.call(bib) } }
             .first
  rescue Alma::StandardError => e
    handle_alma_error(client_error: e)
  end

  # Returns availability for a list of bib ids
  def get_availability_many(ids:, deep_check: false)
    options = { timeout: 20 }
    AlmaAdapter::Execute.call(options:, message: "Find bibs #{ids.join(',')}") do
      bibs = Alma::Bib.find(Array.wrap(ids), expand: ["p_avail", "e_avail", "d_avail", "requests"].join(",")).each
      return nil if bibs.count == 0
      availability = bibs.each_with_object({}) do |bib, acc|
        acc[bib.id] = AvailabilityStatus.new(bib:, deep_check:).bib_availability
      end
      availability
    end
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
    holding_items = bib_status.holding_item_data(holding_id:)
    holding_items[:items].map(&:availability_summary)
  rescue Alma::StandardError => e
    handle_alma_error(client_error: e)
  end

  # Returns list of holding records for a given MMS
  # @param id [string]. e.g id = "991227850000541"
  def get_holding_records(id)
    res = connection.get(
      "bibs/#{id}/holdings",
      apikey:
    )

    res.body.force_encoding("utf-8") if validate_response!(response: res)
  end

  # @param id [String]. e.g id = "991227850000541"
  # @return [AlmaAdapter::BibItemSet]
  def get_items_for_bib(id)
    alma_options = { timeout: 10 }
    AlmaAdapter::Execute.call(options: alma_options, message: "Find items for bib #{id}") do
      find_options = { limit: Alma::BibItemSet::ITEMS_PER_PAGE, expand: "due_date_policy,due_date", order_by: "library", direction: "asc" }
      bib_items = Alma::BibItem.find(id, find_options).all.map { |item| AlmaAdapter::AlmaItem.new(item) }
      AlmaAdapter::BibItemSet.new(items: bib_items, adapter: self)
    end
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
    holding = Alma::BibHolding.find(mms_id:, holding_id:)
    if holding["errorsExist"]
      # In this case although `holding` is an object of type Alma::BibHolding, its
      # content is really an HTTPartyResponse with the error information. :shrug:
      error = Alma::StandardError.new(holding.holding.parsed_response.to_s)
      handle_alma_error(client_error: error)
    end
    holding
  end

  def find_user(patron_id)
    options = { enable_loggable: true }
    AlmaAdapter::Execute.call(options:, message: "Find user #{patron_id}") do
      return Alma::User.find(patron_id, expand: '')
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
end
