require 'rails_helper'

# rubocop:disable RSpec/FilePath
RSpec.describe MARC::Record do
  describe '#date_from_008' do
    it 'can handle bad data in the 008' do
      record = described_class.new_from_hash(
        'fields' => [
          { '008' => '251231' }
        ]
      )
      expect(record.date_from_008).to be_nil
    end
  end
end
# rubocop:enable RSpec/FilePath
