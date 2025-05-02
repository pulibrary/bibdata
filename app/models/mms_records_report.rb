require 'active_support/cache/file_store'

class MmsRecordsReport
  class AuthenticationError < StandardError
    def message
      # For debugging
      # "Authentication error - check figgy auth_token: #{ENV.fetch('CATALOG_SYNC_TOKEN', 'FAKE_TOKEN')}"
      'Authentication error - check figgy auth_token'
    end
  end

  def self.endpoint
    # @endpoint ||= (MARC_LIBERATION_CONFIG['figgy_base_url']).to_s
    @endpoint ||= 'https://figgy.princeton.edu'
  end

  def mms_records_report
    # expires_in 24 hours - 60 * 60 * 24 = 86400
    # expiration time in seconds
    mms_report_cache.fetch('mms_records_report', expires_in: 86400) do
      response = MmsRecordsReport.figgy_connection.get('/reports/mms_records.json', { auth_token: ENV.fetch('CATALOG_SYNC_TOKEN', 'FAKE_TOKEN') })
      raise AuthenticationError if response.status == 403

      JSON.parse(response.body)
    end
  end

  def mms_report_cache
    @mms_report_cache ||= ActiveSupport::Cache::FileStore.new('./tmp/cache/')
  end

  def self.figgy_connection
    Faraday.new(
      url: MmsRecordsReport.endpoint,
      headers: { 'Content-Type' => 'application/json' }
    )
  end
end
