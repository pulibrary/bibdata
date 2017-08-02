module Scsb
  extend ActiveSupport::Concern

  # if id comes from 001 source is scsb
  # if id comes from 009 source is the owning library
  def items_by_id(id, source = 'scsb')
    response = self.scsb_conn.post do |req|
      req.url '/sharedCollection/bibAvailabilityStatus'
      req.headers['Content-Type'] = 'application/json'
      req.headers['Accept'] = 'application/json'
      req.headers['api_key'] = scsb_auth_key
      req.body = scsb_bib_id_request(id, source).to_json
    end
    parse_scsb_response(response)
  end

  def items_by_barcode(barcodes)
    response = scsb_conn.post do |req|
      req.url '/sharedCollection/itemAvailabilityStatus'
      req.headers['Content-Type'] = 'application/json'
      req.headers['Accept'] = 'application/json'
      req.headers['api_key'] = scsb_auth_key
      req.body = scsb_barcode_request(barcodes).to_json
    end
    parse_scsb_response(response)
  end

  def scsb_barcode_request(barcodes)
    {
      barcodes: barcodes
    }
  end

  def scsb_bib_id_request(id, source)
    {
      bibliographicId: id,
      institutionId: source
    }
  end

  def scsb_conn
    conn = Faraday.new(url: scsb_server) do |faraday|
      faraday.request  :url_encoded # form-encode POST params
      faraday.response :logger unless Rails.env.test? # log requests to STDOUT
      faraday.adapter  Faraday.default_adapter # make requests with Net::HTTP
    end
    conn
  end

  def parse_scsb_message(message)
    parsed = JSON.parse(message)
    parsed.class == Hash ? parsed.with_indifferent_access : parsed
  end

  def parse_scsb_response(response)
    parsed = response.status == 200 ? JSON.parse(response.body) : {}
    parsed.class == Hash ? parsed.with_indifferent_access : parsed
  end

  private

    def scsb_auth_key
      if !Rails.env.test?
        ENV['SCSB_AUTH_KEY']
      else
        'TESTME'
      end
    end

    def scsb_server
      if !Rails.env.test?
        ENV['SCSB_SERVER']
      else
        'https://test.api.com/'
      end
    end
end
