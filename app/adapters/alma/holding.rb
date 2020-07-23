module Alma
  class Holding
    # VoyagerHelpers::Liberator.get_holding_record
    # VoyagerHelpers::Liberator.get_items_for_holding
    # /almaws/v1/bibs/{mms_id}/holdings/{holding_id}
    # /almaws/v1/bibs/{mms_id}/holdings/{holding_id}/items

    class << self
      def get_holding_record(ids, conn=nil, opts={})
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
    end
  end
end
