module Alma
  class Bib

    # It can be an array of ids or one id.
    # def initialize(ids:)
#       @ids = ids
#     end

    # Get /almaws/v1/bibs Retrieve bibs
    # @param ids [string] one or more ids. e.g ids = "991227850000541, 991227840000541 ,991227830000541" or ids = "991227830000541"
    # @param mms_id [string]
    # @param apikey [string]
    # @param view [string]. The default is full. Use brief to retrieve without the full record
    # @param expand [String]. Expands the bibliographic record with: p_avail - Expands physical inventory information, e_avail - Expands electronic inventory information, d_avail - Expand digital inventory information, requests - Expand total number of title requests.
    # get one bib record is supported in the bibdata UI and in the bibliographic_controller
    # @param records an array of MARC::Record records
    class << self
      def get_bib_record(ids, conn=nil, opts={})
        res = Alma::Adapter.connection.get "bibs?mms_id=#{self.ids_remove_spaces(ids: ids)}", {
          :apikey => self.apikey, # I can't stub this in the bib_spec
          :expand => "p_avail,e_avail,d_avail,requests",
          :view => "full"
        }
        reader = MARC::XMLReader.new(StringIO.new(res.body))
        return reader.first unless self.ids_build_array(ids: ids).count > 1
        records = []
        reader.select {|record| records << record}
      end

      # Returns list of holding records for a given MMS
      # @params id [string]. e.g id = "991227850000541"
      def get_holding_records(id)
        res = Alma::Adapter.connection.get "bibs/#{id}/holdings", {
          :apikey => self.apikey
        }
        doc = res.body
      end

      # /almaws/v1/bibs/{mms_id}/holdings/{holding_id}/items
      # Retrieve items list. holding_id=ALL witll retrieve all holdings for a bib.
      def get_bib_items
        
      end
      
      # apikey only to read alma bibs.
      def apikey
        Alma.config[:alma_bibs_read_only_key]
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



