# frozen_string_literal: true

# Class for building electronic portfolio JSON from marc fields
class ElectronicPortfolioBuilder
  # Build electronic portfolio JSON from marc fields
  # @param field [MARC::DataField] data from 951 field

  # @return [String] JSON string
  def self.build(field:)
    new(field:).build
  end

  attr_reader :field

  # Constructor
  # @param field [MARC::DataField] data from 951 field
  def initialize(field:)
    @field = field
  end

  def build
    {
      desc: field['k'],
      title: portfolio_title,
      url: field['x'],
      notes: public_notes
    }.to_json
  end

  private

    def portfolio_title
      field['n'].nil? ? 'Online Content' : field['n']
    end

    def public_notes
      field.select { |s| s.code == 'i' }.map(&:value)
    end
end
