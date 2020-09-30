module AlmaAdapter
  class Connector
    class << self
      def base_path
        "#{region}/almaws/v1"
      end

      def users_path
        "#{base_path}/users"
      end

      # ExLibris Alma region
      def region
        AlmaAdapter.config[:region]
      end

      def url
        @url ||= URI::HTTPS.build(host: region)
      end

      # Exlibris Alma connection
      def connection
        Faraday.new(url: "#{url}/almaws/v1") do |builder|
          builder.adapter Faraday.default_adapter
          builder.response :logger
          builder.request :url_encoded
        end
      end
    end
  end
end
