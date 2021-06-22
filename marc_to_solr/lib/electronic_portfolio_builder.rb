# Class for building electronic portfolio JSON from marc fields
class ElectronicPortfolioBuilder
  # Build electronic portfolio JSON from marc fields
  # @param field [MARC::DataField] data from 951 field
  # @param date [MARC::DataField] date range data from 953 field
  # @param embargo [MARC::DataField] embargo data from 954 field
  # @return [String] JSON string
  def self.build(field:)
    new(field: field).build
  end

  attr_reader :field

  # Constructor
  # @param field [MARC::DataField] data from 951 field
  # @param date [MARC::DataField] date range data from 953 field
  # @param embargo [MARC::DataField] embargo data from 954 field
  def initialize(field:)
    @field = field
  end

  def title
    field['m']
  end

  def desc
    field['s']
  end

  def url
    field['u']
  end

  def build
    {
      'title': title,
      'desc': desc,
      'url': url,
      'start': start_date,
      'end': end_date
    }
  end

  private

    def date_segments
      return [] unless desc

      desc.split(/until/)
    end

    # Formulas for start and end dates come from Alma
    # documentation on the embargo operator:
    def start_date
      date_match = /from\s(.+\s?)?(\d{4})/.match(date_segments.first)
      return unless date_match

      date_match.captures.last
    end

    def end_date
      return 'latest' if date_segments.length < 2

      date_match = /until\s(.+\s?)?(\d{4})/.match(desc)
      return 'latest' unless date_match

      date_match.captures.last
    end
end
