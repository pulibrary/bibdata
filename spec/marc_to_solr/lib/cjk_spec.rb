require 'rails_helper'

describe 'CJK indexing' do
  describe 'cjk_subject' do
    it 'includes subjects in Katakana' do
      record = MARC::Record.new_from_hash(
        'fields' => [
          { '610' => { 'ind1' => ' ', 'ind2' => '0', 'subfields' => [{ '6' => '880-01' }, { 'a' => 'Suzuki' }] } },
          { '880' => { 'ind1' => ' ', 'ind2' => '0', 'subfields' => [{ '6' => '610-01' }, { 'a' => 'スズキ' }] } }
        ],
        'leader' => '01155njs a22003257i 4500'
      )
      indexed = IndexerService.build.map_record(record)
      expect(indexed['cjk_subject']).to include 'スズキ'
    end

    it 'does not include subjects in Arabic script' do
      record = MARC::Record.new_from_hash(
        'fields' => [
          { '610' => { 'ind1' => ' ', 'ind2' => '0', 'subfields' => [{ '6' => '880-01' }, { 'a' => 'Suzuki' }] } },
          { '880' => { 'ind1' => ' ', 'ind2' => '0', 'subfields' => [{ '6' => '610-01' }, { 'a' => 'سوزوكي' }] } }
        ],
        'leader' => '01155njs a22003257i 4500'
      )
      indexed = IndexerService.build.map_record(record)
      expect(indexed['cjk_subject']).not_to be_present
    end
  end
end
