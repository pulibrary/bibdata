class AlmaAdapter
  class AlmaItem
    attr_reader :item
    # @param item [Alma::BibItem]
    def initialize(item)
      @item = item
    end

    def enrichment_876
      MARC::DataField.new(
        '876', '0', '0',
        *subfields_for_876
      )
    end

    def subfields_for_876
      [
        MARC::Subfield.new('0', holding_id),
        MARC::Subfield.new('a', item_id),
        MARC::Subfield.new('p', barcode),
        MARC::Subfield.new('t', copy_number)
      ] + recap_876_fields
    end

    def recap_876_fields
      return [] unless item.library == "recap"
      [
        MARC::Subfield.new('h', recap_use_restriction)
      ]
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

    def recap_use_restriction
      return unless item.library == "recap"
      case item.location
      when 'pj', 'pk', 'pl', 'pm', 'pn', 'pt'
        "In Library Use"
      when "pb", "ph", "ps", "pw", "pz", "xc", "xg", "xm", "xn", "xp", "xr", "xw", "xx"
        "Supervised Use"
      end
    end
  end
end
