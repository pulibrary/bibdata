require 'rails_helper'

RSpec.describe 'Date indexing' do
  describe 'publication_date_citation_display' do
    it 'uses the date from the 008' do
      record = MARC::Record.new_from_hash('fields' => [{ '008' => '240701s2024||||-hkppz|fsaefh#######eng|d' }], 'leader' => '01155njs a22003257i 4500')
      indexed = IndexerService.build.map_record(record)
      expect(indexed['publication_date_citation_display']).to include '2024'
    end

    it 'does not index anything if the 008 date is unknown' do
      record = MARC::Record.new_from_hash('fields' => [{ '008' => '120127uuuuuuuuuuuuuu-|-o----u|----|eng-d' }], 'leader' => '00406nasZa2200145zZZ4500')
      indexed = IndexerService.build.map_record(record)
      expect(indexed).not_to have_key 'publication_date_citation_display'
    end

    it 'does not index anything if the 008 date is partially unknown (e.g. 19uu)' do
      record = MARC::Record.new_from_hash('fields' => [{ '008' => '800916d19uu1931ja uu 0 0eng d' }], 'leader' => '00726cas a2200229M 4500')
      indexed = IndexerService.build.map_record(record)
      expect(indexed).not_to have_key 'publication_date_citation_display'
    end

    it 'does not index anything if the 008 date is 9999' do
      record = MARC::Record.new_from_hash('fields' => [{ '008' => '911219d99999999ohufr-p-------0---a0eng-c' }], 'leader' => '00726cas a2200229M 4500')
      indexed = IndexerService.build.map_record(record)
      expect(indexed).not_to have_key 'publication_date_citation_display'
    end
  end
end
