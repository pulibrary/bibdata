require 'rails_helper'

RSpec.describe 'Language indexing', :rust do
  describe 'language_iana_s' do
    it 'takes the first value that has a two-character equivalent' do
      fields = [
        { '008' => '130515s17uu xx 000 0 ota d' },
        { '041' => { 'ind1' => ' ', 'ind2' => ' ', 'subfields' => [{ 'a' => 'ota' }, { 'a' => 'per' }, { 'a' => 'ara' }] } }
      ]
      record = MARC::Record.new_from_hash('fields' => fields, 'leader' => '03657ctmaa2200673Ii 4500')
      indexed = IndexerService.build.map_record record
      expect(indexed['language_iana_s']).to eq ['fa']
    end

    it 'defaults to english if language is und' do
      fields = [
        { '008' => '130515s17uu xx 000 0 und d' }
      ]
      record = MARC::Record.new_from_hash('fields' => fields, 'leader' => '03657ctmaa2200673Ii 4500')
      indexed = IndexerService.build.map_record record
      expect(indexed['language_iana_s']).to eq ['en']
    end
  end

  describe 'mult_languages_iana_s' do
    it 'does not default to english if language is und' do
      fields = [
        { '008' => '130515s17uu xx 000 0 und d' }
      ]
      record = MARC::Record.new_from_hash('fields' => fields, 'leader' => '03657ctmaa2200673Ii 4500')
      indexed = IndexerService.build.map_record record
      expect(indexed['mult_languages_iana_s']).to be_nil
    end

    it 'takes valid values that have a two-character equivalent' do
      fields = [
        { '008' => '130515s17uu xx 000 0 ota d' },
        { '041' => { 'ind1' => ' ', 'ind2' => ' ', 'subfields' => [{ 'a' => 'ota' }, { 'a' => 'per' }, { 'a' => 'ara' }] } }
      ]
      record = MARC::Record.new_from_hash('fields' => fields, 'leader' => '03657ctmaa2200673Ii 4500')
      indexed = IndexerService.build.map_record record
      expect(indexed['mult_languages_iana_s']).to eq ['fa', 'ar']
    end
  end

  describe 'original_language_of_translation_facet' do
    it 'is an array of English names of original languages' do
      fields = [
        { '041' => { 'ind1' => '1', 'ind2' => ' ', 'subfields' => [{ 'h' => 'gre' }, { 'h' => 'spa' }] } }
      ]
      record = MARC::Record.new_from_hash('fields' => fields, 'leader' => '03657ctmaa2200673Ii 4500')
      indexed = IndexerService.build.map_record record
      expect(indexed['original_language_of_translation_facet']).to eq ['Greek, Modern (1453-)', 'Spanish']
    end
  end
end
