require 'rails_helper'

RSpec.describe 'Subject indexing' do
  describe 'icpsr_subject_unstem_search' do
    it 'takes info from 650 _7 with $2 icpsr' do
      record = MARC::Record.new_from_hash('fields' => [{
                                            '650' => { 'ind1' => ' ', 'ind2' => '7', 'subfields' => [{ 'a' => 'Auto theft. ' }, { '2' => ' icpsr' }] }
                                          }], 'leader' => '01155njs a22003257i 4500')
      indexed = IndexerService.build.map_record(record)
      expect(indexed['icpsr_subject_unstem_search']).to eq ['Auto theft']
    end
  end
end
