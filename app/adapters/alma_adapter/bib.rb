module AlmaAdapter
  class Bib
    class << self
      # Get /almaws/v1/bibs Retrieve bibs
      # @param id [String] e.g. id = "991227830000541"
      # @param _opts not used in the Alma API
      # @param _conn not used in the Alma API
      # @see https://developers.exlibrisgroup.com/console/?url=/wp-content/uploads/alma/openapi/bibs.json#/Catalog/get%2Falmaws%2Fv1%2Fbibs Values that could be passed to the alma API
      # get one bib record is supported in the bibdata UI and in the bibliographic_controller
      # @return [MARC::Record]
      def get_bib_record(id, _conn = nil, _opts = {})
        res = AlmaAdapter::Connector.connection.get(
          "bibs?mms_id=#{id}",
          { query: { expand: "p_avail,e_avail,d_avail,requests" }, apikey: apikey },
          'Accept' => 'application/xml'
        )

        doc = Nokogiri::XML(res.body)
        doc_unsuppressed(doc)
        unsuppressed_marc.first
      end

      # Get /almaws/v1/bibs Retrieve bibs
      # @param ids [Array] e.g. ids = ["991227850000541","991227840000541","99222441306421"]
      # @param _opts not used in the Alma API
      # @param _conn not used in the Alma API
      # @see https://developers.exlibrisgroup.com/console/?url=/wp-content/uploads/alma/openapi/bibs.json#/Catalog/get%2Falmaws%2Fv1%2Fbibs Values that could be passed to the alma API
      # @return [Array<MARC::Record>]
      def get_bib_records(ids, _conn = nil, _opts = {})
        res = AlmaAdapter::Connector.connection.get(
          "bibs?mms_id=#{ids_array_to_string(ids)}",
          { query: { expand: "p_avail,e_avail,d_avail,requests" }, apikey: apikey },
          'Accept' => 'application/xml'
        )

        doc = Nokogiri::XML(res.body)
        doc_unsuppressed(doc)

        unsuppressed_marc.to_a
      end

      # Returns list of holding records for a given MMS
      # @params id [string]. e.g id = "991227850000541"
      def get_holding_records(id)
        res = AlmaAdapter::Connector.connection.get(
          "bibs/#{id}/holdings",
          apikey: apikey
        )
        res.body
      end

      # @params id [string]. e.g id = "991227850000541"
      # @return [Hash] of holdings / items data
      def get_items_for_bib(id)
        opts = { limit: 100, expand: "due_date_policy,due_date" }
        Alma::BibItem.find(id, opts)
        # TODO: transform alma response to marc liberation format
      end

      private

        def doc_unsuppressed(doc)
          @doc_unsuppressed = doc.search('//bib').each { |node| node.remove if node.xpath('suppress_from_publishing').text == 'true' }
        end

        def unsuppressed_marc
          MARC::XMLReader.new(StringIO.new(@doc_unsuppressed.at_xpath('//bibs').to_xml))
        end

        def ids_array_to_string(ids)
          ids.join(",")
        end

        def apikey
          AlmaAdapter.config[:bibs_read_only]
        end
    end
  end
end
