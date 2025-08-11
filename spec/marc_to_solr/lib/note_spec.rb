require 'rails_helper'

RSpec.describe 'Notes indexing', :rust do
  describe 'access_restrictions_note_display' do
    it 'indexes notes with first indicator 1 (restrictions apply)' do
      fields = [
        { '506' => { 'ind1' => '1', 'ind2' => ' ', 'subfields' => [{ '3' => 'Princeton copy' }, { 'a' => ' For conservation reasons, access is granted for compelling reasons only: please consult the curator of the Cotsen Children\'s Library. ' }, { '5' => ' NjP' }] } }
      ]
      record = MARC::Record.new_from_hash('fields' => fields, 'leader' => '03657ctmaa2200673Ii 4500')
      indexed = IndexerService.build.map_record record
      expect(indexed['access_restrictions_note_display']).to eq ['For conservation reasons, access is granted for compelling reasons only: please consult the curator of the Cotsen Children\'s Library.']
    end
  end
end
