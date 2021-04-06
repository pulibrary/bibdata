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
    #
    # Note: If the holding has more than 100 items this method will make multiple calls
    #       to ExLibris to fetch them all. This is not a common occurrence but a few records,
    #       like Nature and Science, fall under this category.
    #
    # TODO: This should be moved to the Alma gem.
    def get_holding_items_all(holding_id:, query: nil)
      data = {items: [], total_count: 0}
      page = 0
      page_size = 100
      more_pages = true
      while more_pages do
        # Get the next page of items...
        page += 1
        items, total_count = get_holding_items_page(holding_id: holding_id, page: page, page_size: page_size, query: query)

        # ...add it to our array
        data[:items] += items
        data[:total_count] = total_count

        # ...check if there are more items to fetch
        page_count = (total_count / page_size)
        page_count += 1 if (total_count % page_size) > 0
        more_pages = page < page_count
      end
      data
    end

    # Returns a page of items for a given holding_id in the current bib
    #
    # TODO: This should be moved to the Alma gem.
    def get_holding_items_page(holding_id:, page: 1, page_size: 100, query: nil)
      offset = (page - 1) * page_size
      url = "bibs/#{bib.id}/holdings/#{holding_id}/items?format=json&limit=#{page_size}&offset=#{offset}"

      # The query parameter has a very specific syntax: "field~search_value". The fields
      # that are valid for this API call are: enum_a, enum_b, chron_i, chron_j, and description.
      #
      # The search is case insensitive.
      #
      # For more details see:
      #   https://developers.exlibrisgroup.com/blog/How-we-re-building-APIs-at-Ex-Libris/#BriefSearch and
      #   https://developers.exlibrisgroup.com/alma/apis/docs/bibs/R0VUIC9hbG1hd3MvdjEvYmlicy97bW1zX2lkfS9ob2xkaW5ncy97aG9sZGluZ19pZH0vaXRlbXM=/
      #
      # If needed we could add logic here to combine enum_a and enum_b into a single field for convenience to the Request
      # application.
      if query
        query = query.gsub(" ", "_")  # ExLibris uses underscores instead of spaces in multi-word searches.
        url += "&q=#{query}"
      end

      res = connection.get(url, apikey: apikey)
      data = JSON.parse(res.body.force_encoding("utf-8")) || {}
      items = data["item"] || []
      total = data["total_record_count"] || 0
      return items, total
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

      # This method won't be needed once/if we move get_holding_items() to the Alma gem.
      def connection
        AlmaAdapter::Connector.connection
      end

      # This method won't be needed once/if we move get_holding_items() to the Alma gem.
      def apikey
        Rails.configuration.alma[:read_only_apikey]
      end
  end
end
