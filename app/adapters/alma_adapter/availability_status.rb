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
      availability = {}
      holdings.each do |holding|
        status = holding_status(holding)
        availability[status[:id]] = status
      end
      availability
    end

    # TODO: handle these properties
    #   "copy_number": item["copy_number"],
    #   "on_reserve": "?",              # TODO: "N""
    #   "patron_group_charged": nil,    # TODO: nil
    #   "status": "???",                # TODO: "Not Charged"
    # TODO: Confirm that we need all of these values with the Alma implementation.
    # TODO: Find out if we can get copy_number from Solr (i.e. without hitting ExLibris' API)
    def holding_status(holding)
      status = if holding["holding_id"]
                 {
                   location: holding["location_code"],
                   label: holding["location"],
                   status_label: holding["availability"],
                   more_items: (holding["total_items"] || "").to_i > 1,
                   holding_type: "physical",
                   id: holding["holding_id"]
                 }
               elsif holding["portfolio_pid"]
                 # This kind of data is new with Alma.
                 status = {
                   location: "N/A",
                   label: "N/A",
                   status_label: holding["activation_status"],
                   more_items: nil,
                   holding_type: "portfolio",
                   id: holding["portfolio_pid"]
                 }
               else
                 # TODO: can there be more than one like this per bib?
                 # If so we'll need to use unique IDs here.
                 status = {
                   location: holding["location_code"],
                   label: holding["location"],
                   status_label: holding["availability"],
                   more_items: (holding["total_items"] || "").to_i > 1,
                   holding_type: "other",
                   id: "other"
                 }
               end
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
        more_items: holding["total_items"].to_i > 1,
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
  end
end
