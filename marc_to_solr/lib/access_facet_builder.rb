# Class for building access_facet values
class AccessFacetBuilder
  # Build access facet
  # @param record [MARC::Record]
  # @param context [Traject::Indexer::Context]
  # @return [Array<String>] access values
  def self.build(record:, context:)
    new(record:, context:).build
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
      marc_indicator,
      digitized_in_figgy
    ].uniq.compact
  end

  private

    def electronic_portfolio
      return 'Online' if context.output_hash['electronic_portfolio_s'].present?
    end

    def in_library
      return 'In the Library' if context.output_hash['location_code_s'].present?
    end

    # Return 'online' if record has an 856 field and
    # it's second indicator is 0, 1, or blank
    def marc_indicator
      field = record.find { |f| f.tag == '856' }
      indicator = field.try(:indicator2)

      return 'Online' if ['0', '1', ' '].include?(indicator)
    end

    def digitized_in_figgy
      return 'Online' if context.output_hash['figgy_1display'].present?
      # byebug if record['001'].value == '99118383073506421'
    end
end
