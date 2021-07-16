class AlmaAdapter
  # Handle the differences in holding enrichments done for ReCAP only.
  class RecapAlmaHolding < AlmaHolding
    # ReCAP can't handle a call number with both an 'h' and an 'i' subfield, so
    # combine them both into 'h'
    def enriched_852
      super.map do |original_field|
        original_field.tap do |field|
          call_no = callno_from_852(field)
          field.subfields.delete_if { |s| ['h', 'i'].include? s.code }
          field.append(MARC::Subfield.new('h', call_no))
          combine_location(field)
        end
      end
    end

    private

      # We need to combine 852 b/c for recap.
      def combine_location(field)
        return if field["b"].to_s.include?("$")
        b_code = "#{field['b']}$#{field['c']}"
        field.subfields.delete_if { |s| s.code == 'b' }
        field.append(MARC::Subfield.new('b', b_code))
      end

      # Copied from VoyagerHelpers. Combines h and i into one callnumber.
      def callno_from_852(field)
        call_no = field['h']
        return call_no if call_no.nil?
        call_no << ' ' + field['i'] if field['i']
        call_no.gsub!(/^[[:blank:]]+(.*)$/, '\1')
        call_no
      end
  end
end
