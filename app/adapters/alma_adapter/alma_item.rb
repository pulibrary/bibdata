class AlmaAdapter
  class AlmaItem < SimpleDelegator
    attr_reader :item
    # @param item [Alma::BibItem]
    def initialize(item)
      @item = item
      super(item)
    end

    def self.reserve_location?(library_code, location_code)
      return false if library_code.nil? || location_code.nil?
      Rails.cache.fetch("library_#{library_code}_#{location_code}", expires_in: 30.minutes) do
        # We could get this information from our location table if we want to avoid the Alma API call.
        record = Alma::Location.find(library_code: library_code, location_code: location_code)
        record.response.dig("fulfillment_unit", "value") == "Reserves"
      end
    end

    def composite_location
      "#{library}$#{location}"
    end

    def composite_temp_location
      return unless in_temp_location?
      "#{temp_library}$#{temp_location}"
    end

    def composite_perm_location
      "#{holding_library}$#{holding_location}"
    end

    def composite_location_display
      if in_temp_location?
        composite_temp_location
      else
        composite_location
      end
    end

    def composite_location_label_display
      if in_temp_location?
        holding_location_label(composite_temp_location)
      else
        holding_location_label(composite_location)
      end
    end

    def on_reserve?
      AlmaItem.reserve_location?(library, location)
    end

    # @note This is called type because item_type is the value used in the
    #   /items endpoint. In migrating to Alma this is largely the policy value
    #   with a fallback.
    def type
      return "Gen" unless item_data["policy"]["value"].present?
      item_data["policy"]["value"]
    end

    # 876 field used for enrichment in
    # AlmaAdapter::MarcRecord#enrich_with_item
    def enrichment_876
      MARC::DataField.new(
        '876', '0', '0',
        *subfields_for_876
      )
    end

    def subfields_for_876
      [
        MARC::Subfield.new('0', holding_id),
        MARC::Subfield.new('3', enum_cron),
        MARC::Subfield.new('a', item_id),
        MARC::Subfield.new('p', barcode),
        MARC::Subfield.new('t', copy_number)
      ] + recap_876_fields
    end

    def recap_876_fields
      return [] unless recap_item?
      [
        MARC::Subfield.new('h', recap_use_restriction),
        MARC::Subfield.new('x', group_designation),
        MARC::Subfield.new('z', recap_customer_code),
        MARC::Subfield.new('j', recap_status),
        MARC::Subfield.new('l', "RECAP"),
        MARC::Subfield.new('k', item.holding_library)
      ]
    end

    # Status isn't used for recap records, but 876j is a required field.
    def recap_status
      "Not Used"
    end

    def enum_cron
      return if enumeration.blank? && chronology.blank?
      return enumeration if chronology.blank?
      return chronology if enumeration.blank?
      "#{enumeration} (#{chronology})"
    end

    def enumeration
      enums = []
      enums << item.item_data["enumeration_a"]
      enums << item.item_data["enumeration_b"]
      enums << item.item_data["enumeration_c"]
      enums << item.item_data["enumeration_d"]
      enums << item.item_data["enumeration_e"]
      enums << item.item_data["enumeration_f"]
      enums << item.item_data["enumeration_g"]
      enums << item.item_data["enumeration_h"]
      enums.reject(&:blank?).join(", ")
    end

    def chronology
      chrons = []
      chrons << item.item_data["chronology_i"]
      chrons << item.item_data["chronology_j"]
      chrons << item.item_data["chronology_k"]
      chrons << item.item_data["chronology_l"]
      chrons << item.item_data["chronology_m"]
      chrons.reject(&:blank?).join(", ")
    end

    def holding_id
      item.holding_data["holding_id"]
    end

    def item_id
      item.item_data["pid"]
    end

    def barcode
      item.item_data["barcode"]
    end

    def copy_number
      item.holding_data["copy_id"]
    end

    def call_number
      item.holding_data["call_number"]
    end

    def cdl?
      item.item_data.dig("work_order_type", "value") == "CDL"
    end

    def recap_customer_code
      return unless recap_item?
      return "PG" if item.location[0].casecmp("x").zero?
      item.location.upcase
    end

    def recap_use_restriction
      return unless recap_item?
      case item.location
      when *in_library_recap_groups
        "In Library Use"
      when *supervised_recap_groups
        "Supervised Use"
      end
    end

    def group_designation
      return unless recap_item?
      case item.location
      when 'pa', 'gp', 'qk', 'pf'
        "Shared"
      when *(in_library_recap_groups + supervised_recap_groups + no_access_recap_groups)
        "Private"
      end
    end

    def recap_item?
      all_recap_groups.include?(holding_location)
    end

    def all_recap_groups
      default_recap_groups +
        in_library_recap_groups +
        supervised_recap_groups +
        no_access_recap_groups
    end

    def default_recap_groups
      ["pa", "gp", "qk", "pf"]
    end

    def in_library_recap_groups
      ['pj', 'pk', 'pl', 'pm', 'pn', 'pt']
    end

    def supervised_recap_groups
      ["pb", "ph", "ps", "pw", "pz", "xc", "xg", "xm", "xn", "xp", "xr", "xw", "xx"]
    end

    def no_access_recap_groups
      ['jq', 'pe', 'pg', 'ph', 'pq', 'qb', 'ql', 'qv', 'qx']
    end

    # Returns a JSON representation used for the /items endpoint.
    def as_json
      item["item_data"].merge(
        "id" => item_id,
        "copy_number" => copy_number.to_i,
        "temp_location" => composite_temp_location,
        "perm_location" => composite_perm_location,
        "item_type" => type,
        "cdl" => cdl?
      )
    end

    def availability_summary
      status = calculate_status
      {
        barcode: item_data["barcode"],
        id: item_data["pid"],
        holding_id: holding_id,
        copy_number: holding_data["copy_id"],
        status: status[:code],        # Available
        status_label: status[:label], # Item in place
        status_source: status[:source], # e.g. work_order, process_type, base_status
        process_type: status[:process_type],
        on_reserve: on_reserve? ? "Y" : "N",
        item_type: item_type, # e.g., Gen
        pickup_location_id: library, # firestone
        pickup_location_code: library, # firestone
        location: composite_location, # firestone$stacks
        label: holding_location_label(composite_location), # Firestore Library
        description: item_data["description"], # "v. 537, no. 7618 (2016 Sept. 1)" - new in Alma
        enum_display: enumeration, # in Alma there are many enumerations
        chron_display: chronology # in Alma there are many chronologies
      }.merge(temp_library_availability_summary)
    end

    def temp_library_availability_summary
      if in_temp_location?
        {
          in_temp_library: true,
          temp_library_code: temp_library,
          temp_library_label: holding_location_label(composite_temp_location),
          temp_location_code: composite_temp_location,
          temp_location_label: holding_location_label(composite_temp_location)
        }
      else
        { in_temp_library: false }
      end
    end

    def item_type
      item_data.dig("policy", "value")
    end

    def calculate_status
      return status_from_work_order_type if item_data.dig("work_order_type", "value").present?
      return status_from_process_type if item_data.dig("process_type", "value").present?
      status_from_base_status
    end

    def status_from_work_order_type
      value = item_data["work_order_type"]["value"]
      desc = item_data["work_order_type"]["desc"]

      # Source for values: https://developers.exlibrisgroup.com/alma/apis/docs/xsd/rest_item.xsd/
      # and https://api-na.hosted.exlibrisgroup.com/almaws/v1/conf/departments?apikey=YOUR-KEY&format=json
      code = if value == "Bind" || value == "Pres" || value == "CDL" || value == "AcqWorkOrder"
               "Not Available"
             else
               # "COURSE" or "PHYSICAL_TO_DIGITIZATION"
               "Available"
             end
      { code: code, label: desc, source: "work_order" }
    end

    def status_from_process_type
      # For now we return "Not Available" for any item that has a process_type.
      # You can see a list of all the possible values here:
      #   https://developers.exlibrisgroup.com/alma/apis/docs/xsd/rest_item.xsd/
      value = item_data.dig("process_type", "value")
      desc = item_data.dig("process_type", "desc")

      { code: "Not Available", label: desc, source: "process_type", process_type: value }
    end

    def status_from_base_status
      value = item_data.dig("base_status", "value")
      desc = item_data.dig("base_status", "desc")

      # Source for values: https://developers.exlibrisgroup.com/alma/apis/docs/xsd/rest_item.xsd/
      code = value == "1" ? "Available" : "Not Available"
      { code: code, label: desc, source: "base_status" }
    end

    def holding_location_label(code)
      Locations::HoldingLocation.find_by(code: code)&.label
    end
  end
end
