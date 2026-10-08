# frozen_string_literal: true

# Class for building electronic portfolio JSON from marc fields
class ElectronicPortfolioBuilder
  # Build electronic portfolio JSON from marc fields
  # @param field [MARC::DataField] data from 951 field
  # @param date [MARC::DataField] date range data from 953 field
  # @param embargo [MARC::DataField] embargo data from 954 field
  # @return [String] JSON string
  def self.build(field:, date:, embargo:, source_id:)
    new(field:, date:, embargo:, source_id:).build
  end

  attr_reader :embargo, :field, :date, :source_id

  # Constructor
  # @param field [MARC::DataField] data from 951 field
  # @param date [MARC::DataField] date range data from 953 field
  # @param embargo [MARC::DataField] embargo data from 954 field
  def initialize(field:, date:, embargo:, source_id:)
    @field = field
    @date = date
    @embargo = embargo
    @source_id = source_id
  end

  def build
    {
      desc: field['k'],
      title: portfolio_title,
      source_id: source_id,
      url: field['x'],
      start: start_date,
      end: end_date,
      notes: public_notes
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

    def portfolio_title
      field['n'].nil? ? 'Online Content' : field['n']
    end

    def public_notes
      field.select { |s| s.code == 'i' }.map(&:value)
    end
end
