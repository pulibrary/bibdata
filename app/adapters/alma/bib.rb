module Alma
  class Bib
    # Get /almaws/v1/bibs Retrieve bibs
    # @param ids [string] one or more ids. e.g ids = "991227850000541, 991227840000541 ,991227830000541" or ids = "991227830000541"
    # @param mms_id [string]
    # @param apikey [string]
    # @param view [string]. The default is full. Use brief to retrieve without the full record
    # @param expand [String]. Expands the bibliographic record with: p_avail - Expands physical inventory information, 
    # e_avail - Expands electronic inventory information, 
    # d_avail - Expand digital inventory information, 
    # requests - Expand total number of title requests.
    # get one bib record is supported in the bibdata UI and in the bibliographic_controller
    # @param records an array of MARC::Record records
    class << self
      def get_bib_record(ids, conn=nil, opts={})
        res = Alma::Connector.connection.get("bibs?mms_id=#{self.ids_remove_spaces(ids: ids)}",
        {query: { :expand => "p_avail,e_avail,d_avail,requests" }, :apikey => self.apikey},
        {'Accept' => 'application/xml'} )

        doc = Nokogiri::XML(res.body)
        doc_unsuppressed = doc_unsuppressed(doc)
        reader = MARC::XMLReader.new(StringIO.new(doc_unsuppressed.at_xpath('//bibs').to_xml))

        return reader.first if doc_unsuppressed.xpath('//mms_id').count < 2
        records = []
        reader.select {|record| records << record}
      end

      def doc_unsuppressed(doc)
        doc.search('//bib').each {|node| node.remove if node.xpath('suppress_from_publishing').text == 'true'}
      end

      # Returns list of holding records for a given MMS
      # @params id [string]. e.g id = "991227850000541"
      def get_holding_records(id)
        res = Alma::Connector.connection.get "bibs/#{id}/holdings", {
          :apikey => self.apikey
        }
        doc = res.body
      end

      # apikey only to read alma bibs.
      def apikey
        Alma.config[:bibs_read_only]
      end

      def ids_remove_spaces(ids:)
        ids.gsub(/\s+/,"")
      end

      def ids_build_array(ids:)
        ids.gsub(/\s+/,"").split(',')
      end

    end
  end
end
