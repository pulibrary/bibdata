# frozen_string_literal: true

require 'rails_helper'

RSpec.describe LinkedFieldsExtractor do
  let(:extractor) { described_class.new(MARC::Record.new_from_hash('fields' => fields), '773') }

  describe 'when the subfield w is an alma MMS ID' do
    let(:fields) do
      [
        { '773' => { 'subfields' => [{ 'w' => '9923506421' }] } }
      ]
    end

    it 'returns an array containing the MMS ID' do
      expect(extractor.mms_ids).to eq(['9923506421'])
    end
  end

  describe 'when the subfield w is not an alma MMS ID' do
    let(:fields) do
      [
        { '773' => { 'subfields' => [{ 'w' => '(OCoLC)15390917' }] } }
      ]
    end

    it 'returns an empty array' do
      expect(extractor.mms_ids).to be_empty
    end
  end

  describe 'when the subfield w could be an alma MMS ID, but the prefix is wrong' do
    let(:fields) do
      [
        { '773' => { 'subfields' => [{ 'w' => '(OCoLC)9923506421' }] } }
      ]
    end

    it 'returns an empty array' do
      expect(extractor.mms_ids).to be_empty
    end
  end

  describe 'when the subfield w is an alma MMS ID with an NjP prefix' do
    let(:fields) do
      [
        { '773' => { 'subfields' => [{ 'w' => '(NjP)9923506421' }] } }
      ]
    end

    it 'returns an array containing the MMS ID' do
      expect(extractor.mms_ids).to eq(['9923506421'])
    end
  end
end
