class BibliographicController < ApplicationController
  include FormattingConcern

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

    records = VoyagerHelpers::Liberator.get_bib_record(sanitize(params[:bib_id]), nil, opts)


    if records.nil?
      render plain: "Record #{params[:bib_id]} not found or suppressed", status: 404
    else
      respond_to do |wants|
        wants.json  {
          json = MultiJson.dump(pass_records_through_xml_parser(records))
          render json: json
        }
        wants.xml {
          xml = records_to_xml_string(records)
          render xml: xml
        }
      end
    end
  end

  def bib_solr
    opts = {
      holdings: params.fetch('holdings', 'true') == 'true',
      holdings_in_bib: params.fetch('holdings_in_bib', 'true') == 'true'
    }

    records = VoyagerHelpers::Liberator.get_bib_record(sanitize(params[:bib_id]), nil, opts)

    if records.nil?
      render plain: "Record #{params[:bib_id]} not found or suppressed", status: 404
    else
      solr_doc = indexer.map_record(records)
      render json: solr_doc
    end
  end

  def indexer
    @indexer ||= setup_indexer
  end

  def setup_indexer
    c = File.join(Rails.root, 'lib', 'traject_config.rb')
    indexer = Traject::Indexer.new
    indexer.load_config_file(c)
    indexer
  end

  def bib_holdings
    records = VoyagerHelpers::Liberator.get_holding_records(sanitize(params[:bib_id]))
    if records.empty?
      render plain: "Record #{params[:bib_id]} not found or suppressed", status: 404
    else
      respond_to do |wants|
        wants.json  {
          json = MultiJson.dump(pass_records_through_xml_parser(records))
          render json: json
        }
        wants.xml {
          xml = records_to_xml_string(records)
          render xml: xml
        }
      end
    end
  end

  def bib_items
    records = VoyagerHelpers::Liberator.get_items_for_bib(sanitize(params[:bib_id]))
    if records.empty?
      render plain: "Record #{params[:bib_id]} not found or suppressed", status: 404
    else
      respond_to do |wants|
        wants.json  { render json: MultiJson.dump(records) }
        wants.xml { render xml: '<todo but="You probably want JSON anyway" />' }
      end
    end
  end

end
