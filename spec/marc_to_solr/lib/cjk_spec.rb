require 'rails_helper'

describe 'CJK indexing', :indexing, :rust do
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

  describe 'cjk_notes' do
    it 'includes Vietnamese written in chữ Nôm characters' do
      record = MARC::Record.new_from_hash(
        'fields' => [
          { '500' => { 'ind1' => ' ', 'ind2' => '0', 'subfields' => [{ '6' => '880-01' }, { 'a' => 'Thạch thất hợp tuyển' }] } },
          { '880' => { 'ind1' => ' ', 'ind2' => '0', 'subfields' => [{ '6' => '500-01' }, { 'a' => '石室合選' }] } }
        ],
        'leader' => '01155njs a22003257i 4500'
      )
      indexed = IndexerService.build.map_record(record)
      expect(indexed['cjk_notes']).to include '石室合選'
    end

    it 'does not include Vietnamese written in Latin characters' do
      record = MARC::Record.new_from_hash(
        'fields' => [
          { '500' => { 'ind1' => ' ', 'ind2' => '0', 'subfields' => [{ '6' => '880-01' }, { 'a' => 'Thạch thất hợp tuyển' }] } },
          { '880' => { 'ind1' => ' ', 'ind2' => '0', 'subfields' => [{ '6' => '500-01' }, { 'a' => 'Thạch thất hợp tuyển' }] } }
        ],
        'leader' => '01155njs a22003257i 4500'
      )
      indexed = IndexerService.build.map_record(record)
      expect(indexed['cjk_notes']).not_to be_present
    end

    it 'includes CJK characters even if they are not in an 880 field' do
      record = MARC::Record.new_from_hash(
        'fields' => [
          { '500' => { 'ind1' => ' ', 'ind2' => '0', 'subfields' => [{ 'a' => '石室合選' }] } }
        ],
        'leader' => '01155njs a22003257i 4500'
      )
      indexed = IndexerService.build.map_record(record)
      expect(indexed['cjk_notes']).to include '石室合選'
    end
  end
end
