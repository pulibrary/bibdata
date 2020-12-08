class AlmaAdapter
  # Responsible for converting an Alma::BibSet to an array of unsuppressed MARC
  # records.
  class MarcResponse
    attr_reader :bibs
    # @param bibs [Alma::BibSet]
    def initialize(bibs:)
      @bibs = bibs
      remove_suppressed!
    end

    def unsuppressed_marc
      return [] unless bibs.present?
      MARC::XMLReader.new(bib_marc_xml).to_a
    end

    private

      def bib_marc_xml
        StringIO.new(
          bibs.flat_map do |bib|
            bib["anies"]
          end.join("")
        )
      end

      def remove_suppressed!
        bibs.reject! do |bib|
          bib["suppress_from_publishing"] == "true"
        end
      end
  end
end
