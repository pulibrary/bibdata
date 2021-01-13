class AlmaAdapter
  # Responsible for converting an Alma::BibSet to an array of unsuppressed MARC
  # records.
  class MarcResponse
    attr_reader :bibs
    # @param bibs [Alma::BibSet]
    def initialize(bibs:)
      @bibs = bibs
    end

    def unsuppressed_marc
      marc_records.reject(&:suppressed?)
    end

    class MarcRecord < SimpleDelegator
      attr_reader :bib
      def initialize(bib, marc_record)
        super(marc_record)
        @bib = bib
      end

      def suppressed?
        bib["suppress_from_publishing"] == "true"
      end
    end

    private

      def marc_records
        @marc_records ||=
          begin
            MARC::XMLReader.new(bib_marc_xml).to_a.each_with_index.map do |record, idx|
              MarcRecord.new(bibs[idx], record)
            end
          end
      end

      def bib_marc_xml
        StringIO.new(
          bibs.flat_map do |bib|
            bib["anies"]
          end.join("")
        )
      end
  end
end
