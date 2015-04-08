require 'oci8'
require 'marc'
require_relative 'queries'
require_relative 'oracle_connection'

module VoyagerHelpers
  class Liberator
    class << self
      include VoyagerHelpers::Queries
      include VoyagerHelpers::OracleConnection

      # @param bib_id [Fixnum] A bib record id
      # @option opts [Boolean] :holdings (true) Include holdings?
      # @option opts [Boolean] :holdings_in_bib (true) Copy 852 fields to the bib record?
      # @return [MARC::Record] If `holdings: false` or there are no holdings.
      # @return [Array<MARC::Record>] If `holdings: true` (default) and there
      #   are holdings.
      def get_bib_record(bib_id, conn=nil, opts={})
        unless bib_is_suppressed?(bib_id, conn)
          if opts.fetch(:holdings, true)
            if conn.nil?
              connection do |c|
                get_bib_with_holdings(bib_id, c, opts)
              end
            else
              get_bib_with_holdings(bib_id, conn, opts)
            end
          else
            if conn.nil?
              connection do |c|
                get_bib_without_holdings(bib_id, c)
              end
            else
              get_bib_without_holdings(bib_id, conn)
            end
          end
        end
      end

      # @param mfhd_id [Fixnum] A holding record id
      # @return [MARC::Record]
      def get_holding_record(mfhd_id, conn=nil)
        unless mfhd_is_suppressed?(mfhd_id, conn)
          segments = get_mfhd_segments(mfhd_id, conn)
          MARC::Reader.decode(segments.join(''), :external_encoding => "UTF-8") unless segments.empty?
        end
      end

      # @param bib_id [Fixnum] A bib record id
      # @return [Array<MARC::Record>]
      def get_holding_records(bib_id, conn=nil)
        records = []
        get_bib_mfhd_ids(bib_id, conn).each do |mfhd_id|
          record = get_holding_record(mfhd_id, conn)
          records << record unless record.nil?
        end
        records
      end

      # @return [<Hash>]
      def get_item_statuses
        query = VoyagerHelpers::Queries.statuses
        statuses = {}
        connection do |c|
          c.exec(query) { |id,desc| statuses.store(id,desc) }
        end
        statuses
      end

      def get_items_for_holding(mfhd_id, conn=nil)
        if conn.nil?
          connection do |c|
            accumulate_items_for_holding(mfhd_id, c)
          end
        else
          accumulate_items_for_holding(mfhd_id, conn)
        end
      end

      def get_item(item_id, conn=nil)
        if conn.nil?
          connection do |c|
            get_info_for_item(item_id, c)
          end
        else
          get_info_for_item(item_id, conn)
        end
      end

      def get_locations
        query = VoyagerHelpers::Queries.all_locations
        locations = {}
        connection do |c|
          c.exec(query) do |id, code, display_name, suppress|
            locations[id] = {}
            locations[id][:code] = code
            locations[id][:display_name] = display_name
            locations[id][:suppress] = suppress
          end
        end
        locations
      end

      # This fires off quite a few queries; could probably be optimized
      def get_items_for_bib(bib_id)
        connection do |c|
          items = []
          mfhds = get_holding_records(bib_id, c)
          if mfhds.empty?
            get_approved_orders(bib_id, c)
          else
            mfhds.each do |mfhd|
              mfhd_hash = mfhd.to_hash
              mfhd_id = id_from_mfhd_hash(mfhd_hash)
              data = { holding_id: mfhd_id.to_i }
              # Everyone seems quite sure that we don't repeat 852 per mfhd
              field_852 = fields_from_marc_hash(mfhd_hash, '852').first['852']
              data[:perm_location] = location_from_852(field_852)
              data[:call_number] = callno_from_852(field_852)
              notes = holdings_notes_from_mfhd_hash(mfhd_hash)
              data[:notes] = notes unless notes.empty?
              holding_items = get_items_for_holding(mfhd_id, c)
              unless holding_items.empty?
                data[:items] = []
                holding_items.each do |item|
                  data[:items] << item
                end
                data[:items].sort_by! { |i| i[:item_sequence_number] }.reverse!
              end
              items << data
            end
          end
          group_items(items)
        end
      end

      def dump_bibs_to_file(ids, file_name, opts={})
        writer = MARC::XMLWriter.new(file_name)
        connection do |c|
          ids.each do |id|
            r = VoyagerHelpers::Liberator.get_bib_record(id, c)
            writer.write(r) unless r.nil?
          end
        end
        writer.close()
      end

      private

      def group_items(data_arr)
        hsh = data_arr.group_by { |holding| holding[:perm_location] }
        hsh.each do |location, holding_arr|
          holding_arr.each do |holding|
            holding.delete(:perm_location)
            holding.fetch(:items, []).each do |i|
              i.delete(:perm_location)
            end
          end
        end
        hsh
      end

      # Note that the hash is the result of calling `to_hash`, not `to_marchash`
      def fields_from_marc_hash(hsh, codes)
        codes = [codes] if codes.kind_of? String
        hsh['fields'].select { |f| codes.include?(f.keys.first) }
      end

      def subfields_from_field(field, codes)
        codes = [codes] if codes.kind_of? String
        field['subfields'].select { |s| codes.include?(s.keys.first) }
      end

      def id_from_mfhd_hash(hsh)
        hsh['fields'].select { |f| f.has_key?('001') }.first['001']
      end

      def holdings_notes_from_mfhd_hash(hsh)
        notes = []
        f866_arr = fields_from_marc_hash(hsh, '866')
        f866_arr.each do |f|
          text_holdings = subfields_from_field(f['866'], 'a')
          public_note = subfields_from_field(f['866'], 'z')
          notes << text_holdings.first['a'] unless text_holdings.empty?
          notes << public_note.first['z'] unless public_note.empty?
        end
        notes
      end

      def callno_from_852(hsh_852)
        subfields = hsh_852.fetch('subfields', {})
        vals = subfields_from_field(hsh_852, ['h','i'])
        parts = []
        subfields_from_field(hsh_852, ['h','i']).each do |sf|
          parts << sf.values()
        end
        parts.flatten.join (' ')
      end

      def location_from_852(hsh_852)
        subfields = hsh_852.fetch('subfields', {})
        subfields_from_field(hsh_852, 'b').first['b']
      end

      # @param bib_id [Fixnum] A bib record id
      # @return [Array<Hash>] An Array of Hashes with one key: :on_order.
      def get_approved_orders(bib_id, conn=nil)
        query = VoyagerHelpers::Queries.approved_orders(bib_id)
        if conn.nil?
          connection do |c|
            exec_get_approved_orders(query, c)
          end
        else
          exec_get_approved_orders(query, conn)
        end
      end

      def exec_get_approved_orders(query, conn)
        statuses = []
        conn.exec(query) do |bib_id,po_status,order_status,date|
          statuses << { on_order: date.to_datetime }
        end
        statuses
      end

      def mfhd_is_suppressed?(mfhd_id, conn=nil)
        query = VoyagerHelpers::Queries.mfhd_suppressed(mfhd_id)
        if conn.nil?
          connection do |c|
            exec_mfhd_is_suppressed?(query, c)
          end
        else
          exec_mfhd_is_suppressed?(query, conn)
        end
      end

      def exec_mfhd_is_suppressed?(query, conn)
        suppressed = false
        if conn.nil?
          connection do |c|
            suppressed = c.select_one(query) == ['Y']
          end
        else
          suppressed = conn.select_one(query) == ['Y']
        end
        suppressed
      end


      def get_info_for_item(item_id, conn=nil)
        query = VoyagerHelpers::Queries.item_info(item_id)
        if conn.nil?
          connection do |c|
            exec_get_info_for_item(query, c)
          end
        else
          exec_get_info_for_item(query, conn)
        end
      end

      def exec_get_info_for_item(query, conn)
        info = {}
        conn.exec(query) do |a|
          info[:id] = a.shift
          info[:copy_number] = a.shift
          info[:item_sequence_number] = a.shift
          info[:on_reserve] = a.shift
          info[:perm_location] = a.shift
          info[:temp_location] = a.shift
          info[:status] = a.shift
          date = a.shift
          info[:status_date] = date.to_datetime unless date.nil?
          info[:barcode] = a.shift
        end
        info
      end

      def accumulate_items_for_holding(mfhd_id, conn)
        items = []
        item_ids = get_item_ids_for_holding(mfhd_id, conn)
        item_ids.each do |item_id|
          items << get_info_for_item(item_id, conn)
        end
        items
      end

      def get_item_ids_for_holding(mfhd_id, conn)
        query = VoyagerHelpers::Queries.mfhd_item_ids(mfhd_id)
        if conn.nil?
          connection do |c|
            exec_get_item_ids_for_holding(query, c)
          end
        else
          exec_get_item_ids_for_holding(query, conn)
        end
      end

      def exec_get_item_ids_for_holding(query, conn)
        item_ids = []
        conn.exec(query) { |item_id| item_ids << item_id }
        item_ids.flatten
      end

      def bib_is_suppressed?(bib_id, conn=nil)
        suppressed = false
        query = VoyagerHelpers::Queries.bib_suppressed(bib_id)
        if conn.nil?
          connection do |c|
            suppressed = c.select_one(query) == ['Y']
          end
        else
          suppressed = conn.select_one(query) == ['Y']
        end
        suppressed
      end

      def get_bib_without_holdings(bib_id, conn=nil)
        segments = get_bib_segments(bib_id, conn)
        MARC::Reader.decode(segments.join(''), :external_encoding => "UTF-8") unless segments.empty?
      end

      def get_bib_with_holdings(bib_id, conn=nil, opts={})
        bib = get_bib_without_holdings(bib_id, conn)
        holdings = get_holding_records(bib_id, conn)
        if holdings.empty?
          bib
        elsif opts.fetch(:holdings_in_bib, true)
          merge_852s_into_bib(bib, holdings)
        else
          [bib,holdings].flatten!
        end
      end

      def merge_852s_into_bib(bib, holdings)
        record_hash = bib.to_hash
        record_hash['fields'].delete_if { |f| f.has_key?('852') }
        holdings.each do |holding|
          holding.to_hash['fields'].select { |h| h.has_key?('852') }.each do |h|
            record_hash['fields'] << h
          end
        end
        MARC::Record.new_from_hash(record_hash)
      end

      def get_bib_segments(bib_id, conn=nil)
        query = VoyagerHelpers::Queries.bib(bib_id)
        segments(query, conn)
      end

      def get_mfhd_segments(mfhd_id, conn=nil)
        query = VoyagerHelpers::Queries.mfhd(mfhd_id)
        segments(query, conn)
      end

      def segments(query, conn=nil)
        segments = []
        if conn.nil?
          connection do |c|
            c.exec(query) { |s| segments << s }
          end
        else
          conn.exec(query) { |s| segments << s }
        end
        segments
      end

      def get_bib_mfhd_ids(bib_id, conn=nil)
        query = VoyagerHelpers::Queries.mfhd_ids(bib_id)
        if conn.nil?
          connection do |c|
            exec_get_bib_mfhd_ids(query, c)
          end
        else
          exec_get_bib_mfhd_ids(query, conn)
        end
      end

      def exec_get_bib_mfhd_ids(query, conn)
        ids = []
        if conn.nil?
          connection do |c|
            c.exec(query) { |id| ids << id.first }
          end
        else
          conn.exec(query) { |id| ids << id.first }
        end
        ids
      end



    end # class << self
  end # class Liberator
end # module VoyagerHelpers





