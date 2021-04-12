class BibliographicController < ApplicationController
  include FormattingConcern
  before_action :protect, only: [:update]

  def adapter
    @adapter ||= AlmaAdapter.new
  end

  def index
    if params[:bib_id]
      if params.fetch(:holdings_only, '0') == '1'
        redirect_to action: :bib_holdings, bib_id: params[:bib_id], adapter: params[:adapter], status: :moved_permanently
      elsif params.fetch(:items_only, '0') == '1'
        redirect_to action: :bib_items, bib_id: params[:bib_id], adapter: params[:adapter], status: :moved_permanently
      else
        redirect_to action: :bib, bib_id: params[:bib_id], adapter: params[:adapter], status: :moved_permanently
      end
    else
      render plain: "Record please supply a bib id", status: 404
    end
  end

  def bib
    opts = {
      holdings: params.fetch('holdings', 'true') == 'true',
      holdings_in_bib: params.fetch('holdings_in_bib', 'true') == 'true'
    }

    begin
      records = adapter.get_bib_record(bib_id_param)
    rescue StandardError => e
      Rails.logger.error "Failed to retrieve the record using the bib. ID: #{bib_id_param}: #{e}"
      return head :bad_request
    end

    if records.nil?
      render plain: "Record #{params[:bib_id]} not found or suppressed", status: 404
      Rails.logger.error "Record #{params[:bib_id]} not found or suppressed"
    else
      respond_to do |wants|
        wants.json  do
          json = MultiJson.dump(pass_records_through_xml_parser(records))
          render json: json
        end
        wants.xml do
          xml = records_to_xml_string(records)
          render xml: xml
        end
      end
    end
  end

  def bib_solr(format: nil)
    opts = {
      holdings: params.fetch('holdings', 'true') == 'true',
      holdings_in_bib: params.fetch('holdings_in_bib', 'true') == 'true'
    }
    records = adapter.get_bib_record(bib_id_param)
    if records.nil?
      render plain: "Record #{params[:bib_id]} not found or suppressed", status: 404
    else
      solr_doc = indexer.map_record(records)
      if format == :jsonld
        render json: solr_to_jsonld(solr_doc), content_type: 'application/ld+json'
      else
        render json: solr_doc
      end
    end
  end

  def bib_jsonld
    bib_solr format: :jsonld
  end

  def bib_holdings
    records = adapter.get_holding_records(sanitize(params[:bib_id]))
    if records.empty?
      render plain: "Record #{params[:bib_id]} not found or suppressed", status: 404
    else
      respond_to do |wants|
        wants.json  do
          json = MultiJson.dump(pass_records_through_xml_parser(records))
          render json: json
        end
        wants.xml do
          xml = records_to_xml_string(records)
          render xml: xml
        end
      end
    end
  end

  def bib_items
    records = adapter.get_items_for_bib(bib_id_param)
    if records.nil? || records.empty?
      render plain: "Record #{params[:bib_id]} not found or suppressed", status: 404
    else
      respond_to do |wants|
        wants.json  { render json: MultiJson.dump(add_locator_call_no(records)) }
        wants.xml { render xml: '<todo but="You probably want JSON anyway" />' }
      end
    end
  end

  def update
    records = find_by_id(voyager_opts)
    return render plain: "Record #{sanitized_id} not found or suppressed", status: 404 if records.nil?
    file = Tempfile.new("#{sanitized_id}.mrx")
    file.write(records_to_xml_string(records))
    file.close
    index_job_queue.add(file: file.path)
    redirect_to index_path, flash: { notice: "Reindexing job scheduled for #{sanitized_id}" }
  rescue StandardError => error
    redirect_to index_path, flash: { alert: "Failed to schedule the reindexing job for #{sanitized_id}: #{error}" }
  end

  def item_discharge
    return render plain: "no auth_token provided", status: :unauthorized unless params[:auth_token]
    return render plain: "incorrect auth_token provided", status: :forbidden unless params[:auth_token] == Rails.configuration.alma[:htc_auth_token]
    mms_id = params[:mms_id]
    holding_id = params[:holding_id]
    item_pid = params[:item_pid]
    options = { op: "scan", library: "recap", circ_desk: "DEFAULT_CIRC_DESK", done: "true" }

    use_discharge_key do
      item = Alma::BibItem.scan(mms_id: mms_id, holding_id: holding_id, item_pid: item_pid, options: options)
      respond_to do |wants|
        wants.json  do
          json = item
          render json: json
        end
      end
    end
  end

  private

    def use_discharge_key
      cached_key = Alma.configuration.apikey
      begin
        Alma.configure { |config| config.apikey = Rails.configuration.alma[:item_discharge_apikey] }
        yield
      ensure
        Alma.configure { |config| config.apikey = cached_key }
      end
    end

    # Construct or access the indexing service
    # @return [IndexingService]
    def index_job_queue
      traject_config = Rails.application.config.traject
      solr_config = Rails.application.config.solr
      @index_job_queue ||= IndexJobQueue.new(config: traject_config['config'], url: solr_config['url'])
    end

    # Ensure that the client is authenticated and the user is a catalog administrator
    def protect
      if user_signed_in?
        render plain: "You are unauthorized", status: 403 if !current_user.catalog_admin?
      else
        redirect_to user_cas_omniauth_authorize_path
      end
    end

    # Retrieve and sanitize the Bib. ID from the request parameters
    # @return [String]
    def sanitized_id
      id = params[:bib_id]
      sanitize(id)
    end

    # Generate the options for retrieving bib. records from Voyager
    # @return [Hash]
    def voyager_opts
      {
        holdings: params.fetch('holdings', 'true') == 'true',
        holdings_in_bib: params.fetch('holdings_in_bib', 'true') == 'true'
      }
    end

    # Find all bib. records from Voyager using a bib. ID and optional arguments
    # @param opts [Hash] optional arguments
    # @return [Array<Object>] the set of bib. records
    def find_by_id(opts)
      adapter.get_bib_record(sanitized_id, nil, opts)
    end

    # Access the URL helpers for the application
    # @return [Array<ActionDispatch::Routing::RouteSet::NamedRouteCollection::UrlHelper>]
    def url_helpers
      Rails.application.routes.url_helpers
    end

    # Access the global Traject Object
    # @return [Traject::Indexer] the Traject indexer
    def indexer
      TRAJECT_INDEXER
    end

    # Generate the URL for the application root
    # @return [String] the root URL
    def root_url
      url_helpers.root_url(host: request.host_with_port)
    end

    # Generate a JSON-LD context URI using the root url
    # @return [String] the context URI
    def context_urls
      root_url + 'context.json'
    end

    # Generates the URL for the bibliographic record
    # @return [String] the URL
    def bib_id_url
      url_helpers.show_bib_url(params[:bib_id], host: request.host_with_port)
    end

    # Converts a Solr Document into a JSON-LD graph
    # @param solr_doc [SolrDocument] the Solr Document being transformed
    # @return [Hash] the JSON-LD graph serialized as a Hash
    def solr_to_jsonld(solr_doc = nil)
      { '@context': context_urls, '@id': bib_id_url }.merge(JSONLDRecord.new(solr_doc).to_h)
    end

    # Sanitizes the bib_id HTTP parameter
    # @return [String]
    def bib_id_param
      sanitize(params[:bib_id])
    end

    def add_locator_call_no(records)
      records["f"] = records["f"].map do |record|
        record[:sortable_call_number] = sortable_call_number(record[:call_number])
        record
      end
      records
    end

    def sortable_call_number(call_no)
      return call_no unless call_no =~ /^[A-Za-z]/
      lsort_result = Lcsort.normalize(call_no)
      return lsort_result.gsub('..', '.') unless lsort_result.nil?
      force_number_part_to_have_4_digits(call_no)
    rescue
      call_no
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
