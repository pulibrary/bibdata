# Class for building electronic portfolio JSON from marc fields
class ElectronicPortfolioBuilder
  # Build electronic portfolio JSON from marc fields
  # @param field [MARC::DataField] data from 951 field
  # @param date [MARC::DataField] date range data from 953 field
  # @param embargo [MARC::DataField] embargo data from 954 field
  # @return [String] JSON string
  def self.build(field:, date:, embargo:)
    new(field: field, date: date, embargo: embargo).build
  end

  attr_reader :embargo, :field, :date

  # Constructor
  # @param field [MARC::DataField] data from 951 field
  # @param date [MARC::DataField] date range data from 953 field
  # @param embargo [MARC::DataField] embargo data from 954 field
  def initialize(field:, date:, embargo:)
    @field = field
    @date = date
    @embargo = embargo
  end

  def build
    {
      'desc': field['k'],
      'title': field['n'],
      'url': field['x'],
      'start': start_date,
      'end': end_date
    }.to_json
  end

  private

    def start_date
      return unless date
      date['b']
    end

    def end_date
      return unless date
      if embargo && embargo['c']
        (DateTime.now.year - embargo['c'].to_i).to_s
      elsif date['c']
        date['c']
      else
        'latest'
      end
    end
end
