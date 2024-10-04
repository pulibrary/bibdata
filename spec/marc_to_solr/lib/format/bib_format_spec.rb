require 'rails_helper'
require Rails.root.join('marc_to_solr', 'lib', 'format', 'bib_format.rb').to_s

RSpec.describe BibFormat do
  describe '#code' do
    it 'defaults to an empty array' do
      bib_format = described_class.new(MARC::Record.new)
      expect(bib_format.code).to eq([])
    end
    it 'returns WM (microform) if first character of 007 is h' do
      record = MARC::Record.new
      physical_description_fixed_field = MARC::ControlField.new("007", "hd adb016bucu")
      record.append physical_description_fixed_field

      bib_format = described_class.new(record)
      expect(bib_format.code).to eq(['WM'])
    end
    it 'returns AJ (journal) and WM (microform) if it is a microform that was originally a journal' do
      record = MARC::Record.new
      physical_description_fixed_field = MARC::ControlField.new("007", "hd adb016bucu")
      record.leader = '02179cas a2200481 a 4500'
      record.append physical_description_fixed_field

      bib_format = described_class.new(record)
      expect(bib_format.code).to contain_exactly 'WM', 'AJ'
    end
    it 'returns MS (musical score), MW (manuscript), and WM (microform) if it is a microform that was originally a manuscript musical score' do
      record = MARC::Record.new
      physical_description_fixed_field = MARC::ControlField.new("007", "hd adb016bucu")
      record.leader = '01765cdm a2200349 a 4500'
      record.append physical_description_fixed_field

      bib_format = described_class.new(record)
      expect(bib_format.code).to contain_exactly 'MS', 'MW', 'WM'
    end
  end
end
