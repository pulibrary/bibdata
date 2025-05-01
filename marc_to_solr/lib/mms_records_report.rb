require 'byebug'
class MmsRecordsReport
  class AuthenticationError < StandardError
    def message
      "Authentication error - check figgy auth_token"
    end
  end

  def self.endpoint
    @endpoint ||= 'https://figgy.princeton.edu'
  end

  def mms_records_report
    response = MmsRecordsReport.figgy_connection.get('/reports/mms_records.json', { auth_token: ENV.fetch('CATALOG_SYNC_TOKEN', 'FAKE_TOKEN') })
    raise AuthenticationError if response.status == 403

    JSON.parse(response.body)
  end

  def self.figgy_connection
    Faraday.new(
      url: MmsRecordsReport.endpoint,
      headers: { 'Content-Type' => 'application/json' }
    )
  end
end
