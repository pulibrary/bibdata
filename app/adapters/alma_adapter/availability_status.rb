class AlmaAdapter
  class AvailabilityStatus
    # @param bib [Alma::Bib]
    def self.from_bib(bib:)
      new(bib: bib)
    end

    attr_reader :bib
    def initialize(bib:)
      @bib = bib
    end

    # Returns availability information for each of the holdings in the Bib record.
    def bib_availability
      availability = holdings.each_with_object({}) do |holding, acc|
        status = holding_status(holding)
        acc[status[:id]] = status
      end
      availability
    end

    # TODO: handle these properties
    #   "copy_number": item["copy_number"],
    #   "patron_group_charged": nil,    # TODO: nil
    #   "status": "???",                # TODO: "Not Charged"
    # TODO: Confirm that we need all of these values with the Alma implementation.
    # TODO: Find out if we can get copy_number from Solr (i.e. without hitting ExLibris' API)
    def holding_status(holding)
      status_label = Status.new(bib: bib, holding: holding, holding_item_data: nil).to_s
      status = if holding["holding_id"]
                 {
                   on_reserve: "N",
                   location: holding["library_code"] + "$" + holding["location_code"],
                   label: holding["location"],
                   status_label: status_label,
                   cdl: false,
                   holding_type: "physical",
                   id: holding["holding_id"]
                 }
               elsif holding["portfolio_pid"]
                 # This kind of data is new with Alma.
                 {
                   on_reserve: "N",
                   location: "N/A",
                   label: "N/A",
                   status_label: status_label,
                   cdl: false,
                   holding_type: "portfolio",
                   id: holding["portfolio_pid"]
                 }
               else
                 # TODO: can there be more than one like this per bib?
                 # If so we'll need to use unique IDs here.
                 {
                   on_reserve: "N",
                   location: holding["location_code"],
                   label: holding["location"],
                   status_label: status_label,
                   cdl: false,
                   holding_type: "other",
                   id: "other"
                 }
               end

      # Check if the item is available via CDL.
      # Notice that we only do this when necessary because it requires an extra (slow-ish) API call.
      check_cdl = status[:holding_type] == "physical" && status[:status_label] == "Unavailable"
      status[:cdl] = cdl_holding?(holding["holding_id"]) if check_cdl

      status
    end

    def to_h
      holdings.each_with_object({}) do |holding, acc|
        acc[holding["holding_id"]] = holding_summary(holding)
      end
    end

    def holding_summary(holding)
      holding_item_data = item_data[holding["holding_id"]]
      status = Status.new(bib: bib, holding_item_data: holding_item_data, holding: holding)
      {
        item_id: holding_item_data&.first&.item_data&.fetch("pid", nil),
        location: "#{holding['library_code']}-#{holding['location_code']}",
        copy_number: holding_item_data&.first&.holding_data&.fetch('copy_id', ""),
        label: holding['library'],
        status: status.to_s
      }
    end

    def item_data
      # This method DOES issue a separate call to the Alma API to get item information.
      # Internally this call passes "ALL" to ExLibris to get data for all the holdings
      # in the current bib record.
      @item_data ||= Alma::BibItem.find(bib.id).items.group_by do |item|
        item["holding_data"]["holding_id"]
      end
    end

    def marc_record
      @marc_record ||= MARC::XMLReader.new(StringIO.new(bib.response["anies"].join(""))).to_a.first
    end

    def holdings
      # This method does NOT issue a separate call to the Alma API to get the information, instead it
      # extracts the availability information (i.e. the AVA and AVE fields) from the bib record.
      @availability_response ||= Alma::AvailabilityResponse.new(Array.wrap(bib)).availability[bib.id][:holdings]
    end

    def holding(holding_id:)
      holdings.find { |h| h["holding_id"] == holding_id }
    end

    # Returns all the items for a given holding_id in the current bib.
    # This is a more specific version of `item_data`.
    #
    # Note: If the holding has more than 100 items this method will make multiple calls
    #       to ExLibris to fetch them all. The need to iterate through multuple pages
    #       is not a common but it does happen for a few of our records, like Nature
    #       and Science.
    def holding_item_data(holding_id:, page_size: 100, query: nil)
      data = { items: [], total_count: 0 }
      page = 0
      more_pages = true
      while more_pages
        # Get the next page of items...
        page += 1
        response = holding_item_data_page(holding_id: holding_id, page: page, page_size: page_size, query: query)

        # ...add it to our array
        data[:items] += response.items.map { |item| AlmaAdapter::AlmaItem.new(item) }
        data[:total_count] = response.total_record_count

        # ...check if there are more items to fetch
        page_count = (response.total_record_count / page_size)
        page_count += 1 if (response.total_record_count % page_size) > 0
        more_pages = page < page_count
      end
      data
    end

    # Returns a page of items for a given holding_id in the current bib
    def holding_item_data_page(holding_id:, page:, page_size:, query: nil)
      options = {
        holding_id: holding_id,
        limit: page_size,
        offset: (page - 1) * page_size
      }

      # The query parameter has a very specific syntax: "field~search_value". The fields
      # that are valid for this API call are: enum_a, enum_b, chron_i, chron_j, and description.
      #
      # The search is case insensitive and uses underscores (instead of spaces) to separate words
      # in multi-word searches.
      #
      # For more details see:
      #   https://developers.exlibrisgroup.com/blog/How-we-re-building-APIs-at-Ex-Libris/#BriefSearch and
      #   https://developers.exlibrisgroup.com/alma/apis/docs/bibs/R0VUIC9hbG1hd3MvdjEvYmlicy97bW1zX2lkfS9ob2xkaW5ncy97aG9sZGluZ19pZH0vaXRlbXM=/
      options[:q] = query.tr(" ", "_") if query

      Alma::BibItem.find(bib.id, options)
    end

    private

      def cdl_holding?(holding_id)
        cdl = false
        item_data[holding_id].each do |bib_item|
          if AlmaItem.new(bib_item).cdl?
            cdl = true
            break
          end
        end
        cdl
      end
  end
end
