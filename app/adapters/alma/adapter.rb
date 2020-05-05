module Alma
  class Adapter

    class << self
      def alma_base_path
        "#{url}/almaws/v1"
      end

      def users_base_path
        "#{alma_base_path}/users"
      end

      # def headers
      #   { "Authorization": "apikey #{apikey}",
      #   "Accept": "application/json",
      #   "Content-Type": "application/json" }
      # end

      private

      def alma_region
        Alma.config[:region]
      end

      def apikey
        Alma.config[:apikey]
      end
      
      # def timeout
      #   Alma.configuration.timeout
      # end

      def url
        @url ||= URI::HTTPS.build(host: alma_region)
      end
    end
  end
end
