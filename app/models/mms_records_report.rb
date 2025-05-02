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
    @endpoint ||= (MARC_LIBERATION_CONFIG['figgy_base_url']).to_s
  end

  def mms_records_report
    Rails.cache.fetch('mms_records_report', expires_in: 24.hours) do
      response = MmsRecordsReport.figgy_connection.get('/reports/mms_records.json', { auth_token: ENV.fetch('CATALOG_SYNC_TOKEN', 'FAKE_TOKEN') })
      raise AuthenticationError if response.status == 403

      JSON.parse(response.body)
    end
  end

  def to_translation_map(translation_map_path: Rails.root.join('marc_to_solr/translation_maps/figgy_mms_ids.yaml'))
    File.write(translation_map_path, open_records.to_yaml)
    translation_map_path
  end

  def open_records
    open_records_hash = {}
    mms_records_report.each do |key, items|
      open_items = items.select { |item| item.dig('visibility', 'label') == 'open' }
      next if open_items.blank?

      open_records_hash[key] = open_items
    end
    open_records_hash
  end

  def self.figgy_connection
    Faraday.new(
      url: MmsRecordsReport.endpoint,
      headers: { 'Content-Type' => 'application/json' }
    )
  end
end
