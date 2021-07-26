# Class for building access_facet values
class AccessFacetBuilder
  # Build access facet
  # @param record [MARC::Record]
  # @param context [Traject::Indexer::Context]
  # @return [Array<String>] access values
  def self.build(record:, context:)
    new(record: record, context: context).build
  end

  attr_reader :record, :context

  # Constructor
  # @param record [MARC::Record]
  # @param context [Traject::Indexer::Context]
  def initialize(record:, context:)
    @record = record
    @context = context
  end

  # @return [Array<String>] access values
  def build
    [
      electronic_portfolio,
      in_library,
      hathi,
      marc_indicator
    ].uniq.compact
  end

  private

    def electronic_portfolio
      return 'Online' if context.output_hash['electronic_portfolio_s'].present?
    end

    def in_library
      return 'In the Library' if context.output_hash['location_code_s'].present?
    end

    def hathi
      return 'Online' if hathi_locations.include?('hathi')
    end

    def hathi_locations
      return [] unless context.output_hash['hathi_identifier_s'].present?
      hathi_line = find_hathi_by_oclc(context.output_hash['oclc_s'].first)
      parse_locations_from_hathi_line(hathi_line)
    end

    # Return 'online' if record has an 856 field and
    # it's second indicator is 0, 1, or blank
    def marc_indicator
      field = record.find { |f| f.tag == '856' }
      indicator = field.try(:indicator2)

      return 'Online' if indicator == '0' || indicator == '1' || indicator == ' '
    end
end
