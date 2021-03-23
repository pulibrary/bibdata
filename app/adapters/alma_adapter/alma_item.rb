class AlmaAdapter
  class AlmaItem < SimpleDelegator
    attr_reader :item
    # @param item [Alma::BibItem]
    def initialize(item)
      @item = item
      super(item)
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
      return [] unless item.library == "recap"
      [
        MARC::Subfield.new('h', recap_use_restriction),
        MARC::Subfield.new('x', group_designation),
        MARC::Subfield.new('z', recap_customer_code),
        MARC::Subfield.new('j', recap_status)
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
      item.item_data["enumeration_a"]
    end

    def chronology
      item.item_data["chronology_i"]
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
      return unless item.library == "recap"
      return "PG" if item.location[0].casecmp("x").zero?
      item.location.upcase
    end

    def recap_use_restriction
      return unless item.library == "recap"
      case item.location
      when *in_library_recap_groups
        "In Library Use"
      when *supervised_recap_groups
        "Supervised Use"
      end
    end

    def group_designation
      return unless item.library == "recap"
      case item.location
      when 'pa', 'gp', 'qk', 'pf'
        "Shared"
      when *(in_library_recap_groups + supervised_recap_groups + no_access_recap_groups)
        "Private"
      end
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
  end
end
