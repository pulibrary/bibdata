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

    # Formulas for start and end dates come from Alma
    # documentation on the embargo operator:
    # <=  Most recent X year(s) available
    # >=  Most recent X year(s) not available
    # <   Most recent X year(s)-1 available
    # >   Most recent X year(s)+1 not available
    def start_date
      if embargo && (embargo['b'] == '<=')
        (DateTime.now.year - embargo['c'].to_i).to_s
      elsif embargo && embargo['b'] == '<'
        (DateTime.now.year - (embargo['c'].to_i - 1)).to_s
      elsif date
        date['b']
      end
    end

    def end_date
      if embargo && (embargo['b'] == '>=')
        (DateTime.now.year - embargo['c'].to_i).to_s
      elsif embargo && (embargo['b'] == '<=')
        'latest'
      elsif embargo && embargo['b'] == '<'
        'latest'
      elsif embargo && embargo['b'] == '>'
        (DateTime.now.year - (embargo['c'].to_i + 1)).to_s
      elsif date && date['c']
        date['c']
      else
        'latest'
      end
    end
end
