# frozen_string_literal: true
require 'rails_helper'

RSpec.describe EmbargoDateExtractor do
  let(:fields) do
    [
      { "506" => { "ind1" => " ", "ind2" => " ", "subfields" => [{ "g" => "20000101", "5" => "NjP" }] } }
    ]
  end
  let(:extractor) { described_class.new(MARC::Record.new_from_hash('fields' => fields)) }
  describe('#dates') do
    it 'has an array of embargo dates' do
      expect(extractor.dates).to contain_exactly(Date.new(2000, 1, 1))
    end
  end
end
