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
          field.subfields.each { |s| s.code = '0' if s.code == '8' }
        end
      end
    end

    private

      # c. location - Append the 852$c value to the 852$b joining with a dollar sign - recap.
      def combine_location(field)
        return if field["b"].to_s.include?("$")
        location = [field['b'], field['c']].join('$')
        field.subfields.delete_if { |s| ['b', 'c'].include? s.code }
        field.append(MARC::Subfield.new('b', location))
      end

      # e. call_number - Append the 852$i value to the 852$h joining with a space
      # (the $h is the subject part of the call numer. $i is the items specific part)
      def callno_from_852(field)
        call_no = field['h']
        return call_no if call_no.nil?
        call_no << ' ' + field['i'] if field['i']
        call_no.gsub!(/^[[:blank:]]+(.*)$/, '\1')
        call_no
      end
  end
end
