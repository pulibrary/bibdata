module Scsb
  extend ActiveSupport::Concern

  # if id comes from 001 source is scsb
  # if id comes from 009 source is the owning library
  def items_by_id(id, source = 'scsb')
    request_body = scsb_bib_id_request(id, source)
    request_body_json = request_body.to_json
    scsb_request('/sharedCollection/bibAvailabilityStatus', request_body_json)
  end

  # Retrieves items from the SCSB endpoint using a barcode
  def items_by_barcode(barcodes)
    request_body = scsb_barcode_request(barcodes)
    request_body_json = request_body.to_json
    scsb_request('/sharedCollection/itemAvailabilityStatus', request_body_json)
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

    def scsb_request(request_path, request_body)
      response = self.scsb_conn.post do |req|
        req.url request_path
        req.headers['Content-Type'] = 'application/json'
        req.headers['Accept'] = 'application/json'
        req.headers['api_key'] = scsb_auth_key
        req.body = request_body
      end
      parse_scsb_response(response)
    rescue Faraday::ConnectionFailed, Faraday::TimeoutError => connection_failed
      Rails.logger.warn("#{self.class}: Connection error for #{scsb_server}")
      raise connection_failed
    end
end
