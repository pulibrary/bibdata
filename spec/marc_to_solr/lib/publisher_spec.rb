require 'rails_helper'

RSpec.describe 'Publisher indexing' do
  describe 'publication_location_citation_display' do
    it 'uses the publisher from a 260 field' do
      record = MARC::Record.new_from_hash('fields' => [{ '260' => {
                                            'ind1' => ' ',
                                            'ind2' => ' ',
                                            'subfields' => [{ 'a' => 'México, D.F. :' }]
                                          } }], 'leader' => '01155njs a22003257i 4500')
      indexed = IndexerService.build.map_record(record)
      expect(indexed['publication_location_citation_display']).to include 'México, D.F.'
    end

    it 'uses the publisher from a 264 field if indicator 2 is 1 (publisher)' do
      record = MARC::Record.new_from_hash('fields' => [{ '264' => {
                                            'ind1' => ' ',
                                            'ind2' => '1',
                                            'subfields' => [{ 'a' => 'Mérida : ' }]
                                          } }], 'leader' => '01155njs a22003257i 4500')
      indexed = IndexerService.build.map_record(record)
      expect(indexed['publication_location_citation_display']).to include 'Mérida'
    end

    it 'does not use the publisher from a 264 field if indicator 2 is 3 (manufacturer)' do
      record = MARC::Record.new_from_hash('fields' => [{ '264' => {
                                            'ind1' => ' ',
                                            'ind2' => '3',
                                            'subfields' => [{ 'a' => 'Mérida : ' }]
                                          } }], 'leader' => '01155njs a22003257i 4500')
      indexed = IndexerService.build.map_record(record)
      expect(indexed).not_to have_key 'publication_location_citation_display'
    end
  end

  describe 'publisher_citation_display' do
    it 'uses the publisher from a 260 field' do
      record = MARC::Record.new_from_hash('fields' => [{ '260' => {
                                            'ind1' => ' ',
                                            'ind2' => ' ',
                                            'subfields' => [{ 'b' => 'Consorcio de la Ciudad Monumental, Histórico-Artística y Arqueológica de Mérida, ' }]
                                          } }], 'leader' => '01155njs a22003257i 4500')
      indexed = IndexerService.build.map_record(record)
      expect(indexed['publisher_citation_display']).to include 'Consorcio de la Ciudad Monumental, Histórico-Artística y Arqueológica de Mérida'
    end

    it 'uses the publisher from a 264 field if indicator 2 is 1 (publisher)' do
      record = MARC::Record.new_from_hash('fields' => [{ '264' => {
                                            'ind1' => ' ',
                                            'ind2' => '1',
                                            'subfields' => [{ 'b' => 'Consorcio de la Ciudad Monumental, Histórico-Artística y Arqueológica de Mérida,' }]
                                          } }], 'leader' => '01155njs a22003257i 4500')
      indexed = IndexerService.build.map_record(record)
      expect(indexed['publisher_citation_display']).to include 'Consorcio de la Ciudad Monumental, Histórico-Artística y Arqueológica de Mérida'
    end
  end
end
