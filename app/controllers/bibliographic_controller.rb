class BibliographicController < ApplicationController
  include FormattingConcern

  def adapter
    @adapter ||= AlmaAdapter.new
  end

  def index
    if params[:bib_id]
      if params.fetch(:holdings_only, '0') == '1'
        redirect_to action: :bib_holdings, bib_id: sanitized_bibid, status: :moved_permanently
      elsif params.fetch(:items_only, '0') == '1'
        redirect_to action: :bib_items, bib_id: sanitized_bibid, status: :moved_permanently
      else
        redirect_to action: :bib, bib_id: sanitized_bibid, status: :moved_permanently
      end
    else
      render plain: 'Record please supply a bib id', status: :not_found
    end
  end

  # Returns availability for a single ID
  # Client: This endpoint is used by orangelight to render status on the catalog
  #   show page
  def availability
    id = params[:bib_id]
    availability = adapter.get_availability_one(id:, deep_check: (params[:deep] == 'true'))
    respond_to do |wants|
      wants.json { render json: availability }
    end
  rescue StandardError => e
    handle_alma_exception(exception: e, message: "Failed to retrieve availability for ID: #{id}")
  end

  # Returns availability for multiple IDs
  # Client: This endpoint is used by orangelight to render status on the catalog
  #   search results page
  def availability_many
    ids = (params[:bib_ids] || '').split(',')
    availability = adapter.get_availability_many(ids:, deep_check: ActiveModel::Type::Boolean.new.cast(params[:deep]))
    respond_to do |wants|
      wants.json { render json: availability }
    end
  rescue StandardError => e
    handle_alma_exception(exception: e, message: "Failed to retrieve availability for IDs: #{ids}")
  end

  # Returns availability for a single holding in a bib record
  # Client: This endpoint is used by Requests to populate a request form and
  #   submit requests to the ILS
  def availability_holding
    if params[:bib_id] && params[:holding_id]
      availability = adapter.get_availability_holding(id: params[:bib_id], holding_id: params[:holding_id])
      respond_to do |wants|
        wants.json { render json: availability, status: availability.nil? ? 404 : 200 }
      end
    else
      render plain: 'Please supply a bib id and a holding id', status: :not_found
    end
  rescue StandardError => e
    handle_alma_exception(exception: e, message: "Failed to retrieve holdings for: #{params[:bib_id]}/#{params[:holding_id]}")
  end

  # Client: This endpoint is used by orangelight to present the staff view
  #   and sometimes by individuals to pull records from the ILS
  def bib
    opts = {
      holdings: params.fetch('holdings', 'true') == 'true',
      holdings_in_bib: params.fetch('holdings_in_bib', 'true') == 'true'
    }

    begin
      records = adapter.get_bib_record(sanitized_bibid)
      records.strip_non_numeric! unless opts[:holdings]
    rescue StandardError => e
      return handle_alma_exception(exception: e, message: "Failed to retrieve the record using the bib. ID: #{sanitized_bibid}")
    end

    if records.nil?
      render plain: "Record #{params[:bib_id]} not found or suppressed", status: :not_found
      Rails.logger.error "Record #{params[:bib_id]} not found or suppressed"
    else
      respond_to do |wants|
        wants.json  do
          json = MultiJson.dump(pass_records_through_xml_parser(records))
          render json:
        end
        wants.xml do
          xml = records_to_xml_string(records)
          render xml:
        end
      end
    end
  end

  # Client: Used by firestone_locator to pull bibliographic data
  #   Also used to pull orangelight and pul_solr test fixtures
  def bib_solr
    opts = {
      holdings: params.fetch('holdings', 'true') == 'true',
      holdings_in_bib: params.fetch('holdings_in_bib', 'true') == 'true'
    }
    records = adapter.get_bib_record(sanitized_bibid)
    if records.nil?
      render plain: "Record #{params[:bib_id]} not found or suppressed", status: :not_found
    else
      solr_doc = indexer.map_record(records)
      render json: solr_doc
    end
  rescue StandardError => e
    handle_alma_exception(exception: e, message: "Failed to retrieve the holding records for the bib. ID: #{sanitized_bibid}")
  end

  # Client: No known use cases
  def bib_holdings
    records = adapter.get_holding_records(sanitized_bibid)
    if records.empty?
      render plain: "Record #{params[:bib_id]} not found or suppressed", status: :not_found
    else
      respond_to do |wants|
        wants.json  do
          json = MultiJson.dump(pass_records_through_xml_parser(records))
          render json:
        end
        wants.xml do
          xml = records_to_xml_string(records)
          render xml:
        end
      end
    end
  rescue StandardError => e
    handle_alma_exception(exception: e, message: "Failed to retrieve the holding records for the bib. ID: #{sanitized_bibid}")
  end

  # bibliographic/:bib_id/items
  # Client: Used by figgy to check CDL status. Used by firestone_locator for
  #   call number and location data
  def bib_items
    item_keys = %w[id pid perm_location temp_location]
    holding_summary = adapter.get_items_for_bib(sanitized_bibid).holding_summary(item_key_filter: item_keys)

    respond_to do |wants|
      wants.json  { render json: MultiJson.dump(add_locator_call_no(holding_summary)) }
      wants.xml { render xml: '<todo but="You probably want JSON anyway" />' }
    end
  rescue Alma::BibItemSet::ResponseError
    render_not_found(params[:bib_id])
  rescue StandardError => e
    handle_alma_exception(exception: e, message: "Failed to retrieve items for bib ID: #{sanitized_bibid}")
  end

  private

    def render_not_found(id)
      render plain: "Record #{id} not found or suppressed", status: :not_found
    end

    # Ensure that the client is authenticated and the user is a catalog administrator
    def protect
      if user_signed_in?
        render plain: 'You are unauthorized', status: :forbidden if !current_user.catalog_admin?
      else
        redirect_to user_cas_omniauth_authorize_path
      end
    end

    # Generate the options for retrieving bib. records from Voyager
    # @return [Hash]
    def voyager_opts
      {
        holdings: params.fetch('holdings', 'true') == 'true',
        holdings_in_bib: params.fetch('holdings_in_bib', 'true') == 'true'
      }
    end

    # Access the URL helpers for the application
    # @return [Array<ActionDispatch::Routing::RouteSet::NamedRouteCollection::UrlHelper>]
    def url_helpers
      Rails.application.routes.url_helpers
    end

    # Access the global Traject Object
    # @return [Traject::Indexer::MarcIndexer] the Traject indexer
    def indexer
      TRAJECT_INDEXER
    end

    # Generate the URL for the application root
    # @return [String] the root URL
    def root_url
      url_helpers.root_url(host: request.host_with_port)
    end

    # Generates the URL for the bibliographic record
    # @return [String] the URL
    def bib_id_url
      url_helpers.show_bib_url(params[:bib_id], host: request.host_with_port)
    end

    # Sanitizes the bib_id HTTP parameter
    # @return [String]
    def sanitized_bibid
      CGI.escape(params[:bib_id])
    end

    def add_locator_call_no(records)
      records.each do |location, holdings|
        next unless location == 'firestone$stacks'

        holdings.each do |holding|
          holding['sortable_call_number'] = sortable_call_number(holding['call_number'])
        end
      end
    end

    def sortable_call_number(call_no)
      return call_no unless /^[A-Za-z]/.match?(call_no)

      call_no = make_sortable_call_number(call_no)
      lsort_result = Lcsort.normalize(call_no)
      return lsort_result.gsub('..', '.') unless lsort_result.nil?

      force_number_part_to_have_4_digits(call_no)
    rescue StandardError
      call_no
    end

    def make_sortable_call_number(call_no)
      tokens = call_no.split(' ')
      needs_adjustment = %w[oversize folio].include? tokens.first.downcase
      return call_no unless needs_adjustment

      # Move the first token (e.g. Oversize or Folio) to the end
      (tokens[1..] << tokens[0]).join(' ')
    end

    # This routine adjust something from "A53.blah" to "A0053.blah" for sorting purposes
    #
    def force_number_part_to_have_4_digits(call_no)
      dot_parts = call_no.tr(',', '.').split('.')
      return call_no if dot_parts.count <= 1

      parts = dot_parts[0].scan(/[A-Za-z]+|\d+/)
      parts[1] = parts[1].rjust(4, '0')
      dot_parts[0] = parts.join('.')
      dot_parts.join('.')
    end
end
