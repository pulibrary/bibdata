class BibliographicController < ApplicationController
  include FormattingConcern
  before_action :protect, only: [:update]

  def index
    if params[:bib_id]
      if params.fetch(:holdings_only, '0') == '1'
        redirect_to action: :bib_holdings, bib_id: params[:bib_id], status: :moved_permanently
      elsif params.fetch(:items_only, '0') == '1'
        redirect_to action: :bib_items, bib_id: params[:bib_id], status: :moved_permanently
      else
        redirect_to action: :bib, bib_id: params[:bib_id], status: :moved_permanently
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
      records = VoyagerHelpers::Liberator.get_bib_record(bib_id_param, nil, opts)
    rescue OCIError => oci_error
      Rails.logger.error "Failed to retrieve the Voyager record using the bib. ID: #{bib_id_param}: #{oci_error}"
      return head :bad_request
    end

    if records.nil?
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

  def bib_solr(format: nil)
    opts = {
      holdings: params.fetch('holdings', 'true') == 'true',
      holdings_in_bib: params.fetch('holdings_in_bib', 'true') == 'true'
    }

    records = VoyagerHelpers::Liberator.get_bib_record(sanitize(params[:bib_id]), nil, opts)

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
    records = VoyagerHelpers::Liberator.get_holding_records(sanitize(params[:bib_id]))
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
    records = VoyagerHelpers::Liberator.get_items_for_bib(sanitize(params[:bib_id]))
    if records.nil? || records.empty?
      render plain: "Record #{params[:bib_id]} not found or suppressed", status: 404
    else
      respond_to do |wants|
        wants.json  { render json: MultiJson.dump(records) }
        wants.xml { render xml: '<todo but="You probably want JSON anyway" />' }
      end
    end
  end

  def update
    records = find_by_id(sanitized_id, voyager_opts)

    if records.nil?
      render plain: "Record #{sanitized_id} not found or suppressed", status: 404
    else
      file = Tempfile.new("#{sanitized_id}.mrx")
      file.write(records_to_xml_string(records))
      file.close
      index_job_queue.add(file: file.path)

      flash[:notice] = "Reindexing job scheduled for #{sanitized_id}"
    end
  rescue StandardError => error
    flash[:alert] = "Failed to schedule the reindexing job for #{sanitized_id}: #{error}"
  ensure
    redirect_to index_path
  end

  private

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
    # @param id [String] the bib. ID
    # @param opts [Hash] optional arguments
    # @return [Array<Object>] the set of bib. records
    def find_by_id(id, opts)
      VoyagerHelpers::Liberator.get_bib_record(id, nil, opts)
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
    def solr_to_jsonld(solr_doc=nil)
      { '@context': context_urls, '@id': bib_id_url }.merge(JSONLDRecord.new(solr_doc).to_h)
    end

    # Sanitizes the bib_id HTTP parameter
    # @return [String]
    def bib_id_param
      sanitize(params[:bib_id])
    end
end
