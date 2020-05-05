module Voyager
  class Adapter
   
      class << self
      def connection(conn=nil)
        if conn.nil?
          begin
            conn = OCI8.new(
              Voyager.config[:dbuser],
              Voyager.config[:dbpassword],
              Voyager.config[:dbname]
            )
            yield conn
          rescue NameError
            return if ENV['CI']
          ensure
            conn.logoff unless conn.nil?
          end
        else
          yield conn
        end
      end

      # Retrieves the availability status of a holding from Voyager
      # @param [Array<String>] bib_ids the IDs for bib. items
      # @param [Integer] mfhd the ID for MFHD information
      # @param [Integer] mfhd_serial the ID for MFHD information describing a series
      # @return [Hash] the response containing MFHDs (location and status information) for the requested item(s)
      # def find_availability(bib_ids: nil, mfhd: nil, mfhd_serial: nil, full: true)
      #   return VoyagerHelpers::Liberator.get_current_issues(mfhd_serial) unless mfhd_serial.nil?
      #   return VoyagerHelpers::Liberator.get_full_mfhd_availability(mfhd) unless mfhd.nil?
      #   VoyagerHelpers::Liberator.get_availability(bib_ids, full)
      # rescue OCIError => oci_error
      #   Rails.logger.error "Error encountered when requesting availability status: #{oci_error}"
      #   {}
      # end

      # check p_avail https://developers.exlibrisgroup.com/alma/apis/docs/bibs/R0VUIC9hbG1hd3MvdjEvYmlicy97bW1zX2lkfQ==/  
      def get_current_issues(mfhd_id, conn = nil)
        issues = []
        Voyager::Adapter.connection(conn) do |c|
          cursor = c.parse(Voyager::Query.current_periodicals)
          cursor.bind_param(':mfhd_id', mfhd_id)
          cursor.exec
          while enum = cursor.fetch
            issues << enum.first
          end
          cursor.close
        end
        issues
      end

      def get_full_mfhd_availability(mfhd_id)
        item_availability = []
        items = Voyager::Adapter.get_items_for_holding(mfhd_id)
        items.each do |item|
          item_hash = {}
          item_hash[:barcode] = item[:barcode]
          item_hash[:id] = item[:id]
          item_hash[:location] = item[:perm_location]
          item_hash[:temp_loc] = item[:temp_location] unless item[:temp_location].nil?
          item_hash[:copy_number] = item[:copy_number]
          item_hash[:item_sequence_number] = item[:item_sequence_number]
          item_hash[:status] = item[:status]
          item_hash[:on_reserve] = item[:on_reserve] unless item[:on_reserve].nil?
          due_date = Voyager::Format.format_due_date(item[:due_date], item[:on_reserve])
          item_hash[:due_date] = due_date unless due_date.nil?
          unless item[:enum].nil?
            item_hash[:enum] = item[:enum]
            enum = item[:enum]
            unless item[:chron].nil?
              enum = enum + " (#{item[:chron]})"
              item_hash[:chron] = item[:chron]
            end
            item_hash[:enum_display] = enum
          end
          item_availability << item_hash
        end
        item_availability.sort_by { |i| i[:item_sequence_number] || 0 }.reverse
      end
      
      def get_items_for_holding(mfhd_id, conn=nil)
        items = []
        query = Voyager::Query.all_mfhd_items
        rows = []

        Voyager::Adapter.connection(conn) do |c|
          cursor = c.parse(query)
          cursor.bind_param(':mfhd_id', mfhd_id)
          cursor.exec
          while row = cursor.fetch_hash
            rows << row
          end
          cursor.close
          items = Voyager::Adapter.group_item_info_rows(rows)
        end
        items
      end

      def group_item_info_rows(rows)
        final_items = []
        grouped_items = rows.group_by { |row| row['ITEM_ID'] }
        grouped_items.each do |pair|
          statuses = []
          first_item = pair[1][0]
          info = {}
          info[:id] = first_item['ITEM_ID']
          info[:on_reserve] = first_item['ON_RESERVE']
          info[:copy_number] = first_item['COPY_NUMBER']
          info[:item_sequence_number] = first_item['ITEM_SEQUENCE_NUMBER']
          info[:temp_location] = first_item['TEMP_LOC']
          info[:perm_location] = first_item['LOCATION_CODE']
          enum = first_item['ITEM_ENUM']
          info[:enum] = Voyager::Format.valid_ascii(enum)
          chron = first_item['CHRON']
          info[:chron] = Voyager::Format.valid_ascii(chron)
          info[:barcode] = first_item['ITEM_BARCODE']
          info[:due_date] = first_item['CURRENT_DUE_DATE']
          pair[1].each do |item|
            statuses << item['ITEM_STATUS_DESC']
          end
          info[:status] = statuses
          final_items << info
        end
        final_items
      end

      # @param bibs [Array<Fixnum>] Bib ids
      # @param full [Boolean] true return full availability for single bib, false (default) first 2 holdings
      # @return [Hash] :bib_id_value => [Hash] bib availability
      #
      #
      # Bib availability hash:
      # For the bib's holding records:
      # :holding_id_value => [Hash] holding availability
      #
      # Holding availability hash:
      # :status => [String] Voyager item status for the first item.
      # :location => [String] Holding location code (mainly for debugging)
      # :more_items => [Boolean] Does the holding record have more than 1 item?
      def get_availability(bibs, full=false)
        number_of_mfhds = full ? 0..-1 : 0..1 # all vs first 2
        Voyager::Adapter.connection do |c|
          availability = {}
          bibs.each do |bib_id|
            availability[bib_id] = {}
            mfhds = get_holding_records(bib_id, c)
            mfhds[number_of_mfhds].each do |mfhd|
              mfhd_id = mfhd['001'].value.to_i
              location = mfhd['852'].nil? ? '' : mfhd['852']['b']
              holding_item_ids = get_item_ids_for_holding(mfhd_id, c)

              availability[bib_id][mfhd_id] = {} # holding record availability hash
              availability[bib_id][mfhd_id][:more_items] = holding_item_ids.count > 1
              availability[bib_id][mfhd_id][:location] = location

              availability[bib_id][mfhd_id][:status] = if holding_item_ids.empty?
                order_status = get_order_status(mfhd_id, c)
                if order_status
                  order_status
                elsif location =~ /^elf/
                  'Online'
                else
                  'On Shelf'
                end
              else
                item = get_info_for_item(holding_item_ids.first, c, false)
                unless item[:temp_location].nil?
                  availability[bib_id][mfhd_id][:temp_loc] = item[:temp_location]
                  availability[bib_id][mfhd_id][:course_reserves] = get_courses(holding_item_ids, c).map(&:to_h)
                end
                availability[bib_id][mfhd_id][:copy_number] = item[:copy_number]
                availability[bib_id][mfhd_id][:item_id] = item[:id]
                availability[bib_id][mfhd_id][:on_reserve] = item[:on_reserve]
                due_date = Voyager::Format.format_due_date(item[:due_date], item[:on_reserve])
                availability[bib_id][mfhd_id][:due_date] = due_date unless due_date.nil?
                item[:status]
              end
            end
          end
          _, availability = availability.first if full # return just holding availability hash (single bib)
          availability
        end
      end


    
      # private
      
      #   def dbuser
      #     Voyager.config[:dbuser]
      #   end

      #   def dbname
      #     Voyager.config[:dbname]
      #   end

      #   def dbpassword
      #     Voyager.config[:dbpassword]
      #   end

        # def connection
        #   @connection = OCI8.new(dbuser, password, dbname) 
        # end
    end  
  end
end  
