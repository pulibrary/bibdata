class ScsbFullRecordsRequest
  attr_accessor :scsb_env, :email

  def initialize(scsb_env, email)
    @scsb_env = scsb_env
    @email = email
  end

  def scsb_host
    case scsb_env
    when 'uat'
      'https://uat-recap.htcinc.com:9093'
    when 'production'
      'https://scsb.recaplib.org:9093'
    end
  end

  def scsb_conn
    Faraday.new(url: scsb_host) do |faraday|
      faraday.request(:url_encoded)
    end
  end

  # See https://scsb.recaplib.org:9093/swagger-ui.html#/data-dump-rest-controller/exportDataDump for documentation
  def scsb_request(institution_code)
    response = scsb_conn.get do |req|
      req.path = '/dataDump/exportDataDump'
      req.params['collectionGroupIds'] = '1,2,5,6'
      req.params['emailToAddress'] = email
      req.params['fetchType'] = 10
      req.params['imsDepositoryCodes'] = repository_codes(institution_code)
      req.params['institutionCodes'] = institution_code
      req.params['outputFormat'] = 0
      req.params['requestingInstitutionCode'] = 'PUL'
      req.params['transmissionType'] = 0
      req.headers['Accept'] = '*/*'
      req.headers['api_key'] = scsb_auth_key
    end
    expected_response_body = "Export process has started and we will send an email notification upon completion"
    Rails.logger.error("Received unexpected response: #{response.body}") unless response.body == expected_response_body
    response
  rescue Faraday::ConnectionFailed, Faraday::TimeoutError => connection_failed
    Rails.logger.warn("#{self.class}: Connection error for #{scsb_server}")
    raise connection_failed
  end

  def repository_codes(institution_code)
    case institution_code
    when 'PUL', 'CUL'
      'RECAP'
    when 'HL'
      'RECAP,HD'
    end
  end

  private

    def scsb_auth_key
      if !Rails.env.test?
        ENV['SCSB_AUTH_KEY']
      else
        'TESTME'
      end
    end
end
